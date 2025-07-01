import AppKit
import CoreGraphics
import WebKit
import XCTest

@MainActor
class WebKitSVG2PNG: NSObject {
  private let webView: WKWebView
  private var pngCallback: ((Result<Data, Error>) -> Void)?

  enum Error: Swift.Error {
    case invalidPNGData
    case invalidImageData
    case javascriptError(String)
    case timeout
  }

  override init() {
    let config = WKWebViewConfiguration()
    config.userContentController = WKUserContentController()

    webView = WKWebView(frame: .zero, configuration: config)
    super.init()

    // Set up message handler
    config.userContentController.add(self, name: "svgHandler")

    // Load the HTML template from resource file
    guard let htmlPath = Bundle.module.url(
      forResource: "svg2canvas",
      withExtension: "html"
    ) else {
      // Fallback: try to load from file system for Xcode
      let currentFile = URL(fileURLWithPath: #file)
      let resourcesDir = currentFile
        .deletingLastPathComponent()
        .appendingPathComponent("Resources")
      let fallbackPath = resourcesDir.appendingPathComponent("svg2canvas.html")
      
      if FileManager.default.fileExists(atPath: fallbackPath.path) {
        let html = try! String(contentsOf: fallbackPath)
        webView.loadHTMLString(html, baseURL: nil)
        return
      }
      
      fatalError("Could not find svg2canvas.html resource in bundle or at \(fallbackPath)")
    }
    let html = try! String(contentsOf: htmlPath)
    webView.loadHTMLString(html, baseURL: nil)
  }

  func convert(
    svg: String,
    width: Int,
    height: Int,
    scale: CGFloat = 1.0
  ) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      self.pngCallback = { result in
        continuation.resume(with: result)
      }

      // Prepare the message data
      let message: [String: Any] = [
        "svg": svg,
        "width": width,
        "height": height,
        "scale": scale,
      ]

      // Send SVG to JavaScript
      webView
        .evaluateJavaScript("handleSVG(\(jsonString(from: message)))") { _, error in
          if let error {
            continuation
              .resume(throwing: Error
                .javascriptError(error.localizedDescription)
              )
          }
        }

      // Set timeout
      Task {
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        if self.pngCallback != nil {
          self.pngCallback = nil
          continuation.resume(throwing: Error.timeout)
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

// MARK: - WKScriptMessageHandler

extension WebKitSVG2PNG: WKScriptMessageHandler {
  func userContentController(
    _: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard let body = message.body as? [String: Any] else {
      pngCallback?(.failure(Error.invalidPNGData))
      pngCallback = nil
      return
    }

    if let error = body["error"] as? String {
      pngCallback?(.failure(Error.javascriptError(error)))
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
      pngCallback?(.failure(Error.invalidPNGData))
      pngCallback = nil
    }
  }
}

// MARK: - Test Helper

@MainActor
extension WebKitSVG2PNG {
  func convertToCGImage(
    svg: String,
    width: Int,
    height: Int,
    scale: CGFloat = 1.0
  ) async throws -> CGImage {
    let pngData = try await convert(
      svg: svg,
      width: width,
      height: height,
      scale: scale
    )

    guard let dataProvider = CGDataProvider(data: pngData as CFData),
          let cgImage = CGImage(
            pngDataProviderSource: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
          ) else {
      throw Error.invalidImageData
    }

    return cgImage
  }
}
