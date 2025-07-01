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
    
    self.webView = WKWebView(frame: .zero, configuration: config)
    super.init()
    
    // Set up message handler
    config.userContentController.add(self, name: "svgHandler")
    
    // Load the HTML template
    let html = Self.htmlTemplate
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
        "scale": scale
      ]
      
      // Send SVG to JavaScript
      webView.evaluateJavaScript("handleSVG(\(jsonString(from: message)))") { _, error in
        if let error = error {
          continuation.resume(throwing: Error.javascriptError(error.localizedDescription))
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
  
  private static let htmlTemplate = """
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <style>
      body { margin: 0; }
      canvas { display: none; }
    </style>
  </head>
  <body>
    <canvas id="canvas"></canvas>
    <script>
      function handleSVG(data) {
        try {
          const { svg, width, height, scale } = data;
          
          const img = new Image();
          const canvas = document.getElementById("canvas");
          const ctx = canvas.getContext("2d");
          
          // Set canvas size with scale
          canvas.width = width * scale;
          canvas.height = height * scale;
          
          // Clear canvas
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          
          img.onerror = function(e) {
            window.webkit.messageHandlers.svgHandler.postMessage({
              error: "Failed to load SVG: " + e.toString()
            });
          };
          
          img.onload = function() {
            try {
              // Scale context for high DPI
              ctx.save();
              ctx.scale(scale, scale);
              
              // Draw image
              ctx.drawImage(img, 0, 0, width, height);
              ctx.restore();
              
              // Convert to PNG
              canvas.toBlob(function(blob) {
                if (!blob) {
                  window.webkit.messageHandlers.svgHandler.postMessage({
                    error: "Failed to create PNG blob"
                  });
                  return;
                }
                
                // Convert blob to base64
                const reader = new FileReader();
                reader.onloadend = function() {
                  const base64 = reader.result.split(',')[1];
                  window.webkit.messageHandlers.svgHandler.postMessage({
                    success: true,
                    data: base64
                  });
                };
                reader.onerror = function() {
                  window.webkit.messageHandlers.svgHandler.postMessage({
                    error: "Failed to read blob"
                  });
                };
                reader.readAsDataURL(blob);
              }, 'image/png');
              
            } catch (e) {
              window.webkit.messageHandlers.svgHandler.postMessage({
                error: "Canvas error: " + e.toString()
              });
            }
          };
          
          // Create data URL with proper encoding
          const svgBlob = new Blob([svg], { type: 'image/svg+xml;charset=utf-8' });
          const url = URL.createObjectURL(svgBlob);
          img.src = url;
          
          // Clean up
          img.addEventListener('load', () => URL.revokeObjectURL(url));
          img.addEventListener('error', () => URL.revokeObjectURL(url));
          
        } catch (e) {
          window.webkit.messageHandlers.svgHandler.postMessage({
            error: "General error: " + e.toString()
          });
        }
      }
    </script>
  </body>
  </html>
  """
}

// MARK: - WKScriptMessageHandler

extension WebKitSVG2PNG: WKScriptMessageHandler {
  func userContentController(
    _ userContentController: WKUserContentController,
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