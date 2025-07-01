import AppKit
import CoreGraphics
import WebKit
import XCTest

@MainActor
class WebKitSVG2PNG: NSObject, WKNavigationDelegate {
  private let webView: WKWebView
  private var pngCallback: ((Result<Data, Error>) -> Void)?
  private var readyContinuation: CheckedContinuation<Void, Swift.Error>?
  private var isReady = false
  private let messageHandler: MessageHandler

  private class MessageHandler: NSObject, WKScriptMessageHandler {
    weak var parent: WebKitSVG2PNG?

    func userContentController(
      _: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      parent?.handleMessage(message)
    }
  }

  override init() {
    let config = WKWebViewConfiguration()
    config.userContentController = WKUserContentController()

    webView = WKWebView(frame: .zero, configuration: config)
    messageHandler = MessageHandler()
    super.init()

    messageHandler.parent = self
    config.userContentController.add(messageHandler, name: "svgHandler")
    webView.navigationDelegate = self
    let htmlPath = getCurrentFilePath(#filePath)
      .appendingPathComponent("Resources")
      .appendingPathComponent("svg2canvas.html")
    let html = try! String(contentsOf: htmlPath)
    webView.loadHTMLString(html, baseURL: nil)
  }

  private func ensureReady() async throws {
    guard !isReady else { return }

    try await withCheckedThrowingContinuation { continuation in
      self.readyContinuation = continuation

      Task {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        if self.readyContinuation != nil {
          self.readyContinuation?
            .resume(throwing: Err("WebView failed to load within 2 seconds"))
          self.readyContinuation = nil
        }
      }
    }
  }

  func convert(
    svg: String,
    scale: CGFloat = 1.0
  ) async throws -> Data {
    try await ensureReady()

    return try await withCheckedThrowingContinuation { continuation in
      self.pngCallback = { result in
        continuation.resume(with: result)
      }

      let message: [String: Any] = [
        "svg": svg,
        "scale": scale,
      ]
      webView
        .evaluateJavaScript("handleSVG(\(jsonString(from: message)))") { _, error in
          if let error {
            continuation
              .resume(
                throwing: Err(
                  "JavaScript evaluation failed: \(error.localizedDescription)"
                )
              )
          }
        }

      // Set timeout
      Task {
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        if self.pngCallback != nil {
          self.pngCallback = nil
          continuation
            .resume(
              throwing: Err("SVG to PNG conversion timed out after 5 seconds")
            )
        }
      }
    }
  }

  private func jsonString(from dict: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: dict),
          let string = String(data: data, encoding: .utf8) else {
      return "{}"
    }
    return string
  }
}

// MARK: - WKNavigationDelegate

extension WebKitSVG2PNG {
  func webView(_: WKWebView, didFinish _: WKNavigation!) {
    isReady = true
    readyContinuation?.resume()
    readyContinuation = nil
  }
}

// MARK: - Message Handling

extension WebKitSVG2PNG {
  private func handleMessage(_ message: WKScriptMessage) {
    guard let body = message.body as? [String: Any] else {
      pngCallback?(
        .failure(
          Err(
            "Invalid message format from JavaScript - expected dictionary, got \(type(of: message.body))"
          )
        )
      )
      pngCallback = nil
      return
    }

    if let error = body["error"] as? String {
      pngCallback?(.failure(Err("JavaScript error: \(error)")))
      pngCallback = nil
      return
    }

    if let success = body["success"] as? Bool,
       success,
       let base64 = body["data"] as? String,
       let data = Data(base64Encoded: base64) {
      pngCallback?(.success(data))
      pngCallback = nil
    } else {
      pngCallback?(
        .failure(
          Err("Failed to decode PNG data - missing or invalid base64 data")
        )
      )
      pngCallback = nil
    }
  }
}

// MARK: - Test Helper

@MainActor
extension WebKitSVG2PNG {
  func convertToCGImage(
    svg: String,
    scale: CGFloat = 1.0
  ) async throws -> CGImage {
    let pngData = try await convert(
      svg: svg,
      scale: scale
    )

    guard let dataProvider = CGDataProvider(data: pngData as CFData),
          let cgImage = CGImage(
            pngDataProviderSource: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
          ) else {
      throw Err("Failed to create CGImage from PNG data")
    }

    return cgImage
  }
}
