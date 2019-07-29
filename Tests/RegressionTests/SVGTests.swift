import Base
import libcggen
import WebKit
import XCTest

class SVGTest: XCTestCase {
  let fm = FileManager.default
  let snapshot = WKWebViewSnapshoter().take

  func testFoo() throws {
    let samplesPath = getCurentFilePath().appendingPathComponent("svg_samples")
    let svgs = try fm
      .contentsOfDirectory(at: samplesPath)
      .filter { $0.lastPathComponent.hasSuffix(".svg") }
    let snapshots: [NSImage] = try svgs.map {
      let svg = try String(contentsOf: $0)
      return try snapshot(svg, .init(x: 8, y: 8, width: 50, height: 50))
    }
    XCTAssert(svgs.count > 0)
    print(snapshots)
    zip(svgs, snapshots).forEach {
      let name = $0.0.lastPathComponent
      let url = $0.0.deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("foo")
        .appendingPathComponent(name)
        .appendingPathExtension("png")
      saveImage($0.1, atUrl: url)
    }
  }

  func testSnapshotsNotFlacking() throws {
    let svg = SVG.Document(width: 50, height: 50, viewBox: .init(0, 0, 50, 50), children: [
      .rect(.init(x: 0, y: 0, width: 50, height: 50, fill: .black, fillOpacity: 1)),
    ])
    let xml = XML.el("html", children: [
      .el("style", attrs: ["type": "text/css"], children: [
        .text("html, body {width:100%;height: 100%;margin: 0px;padding: 0px;}"),
      ]),
      svg.xml,
    ])
    let blackPixel = RGBAPixel(bufferPiece: [0, 0, 0, .max])

    let test = { [snapshot] in
      let img = try snapshot(
        xml.render(),
        .init(origin: .zero, size: .square(50))
      )
      let cgimage = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
      let buffer = try cgimage?.rgbaBuffer() !! Error.noImage
      XCTAssert(buffer.pixels.flatMap(identity).allSatisfy {
        $0 == blackPixel
      })
    }
    try (1...10).forEach { _ in try test() }
  }
}

enum Error: Swift.Error {
  case noImage
  case unknownSnapshotError
}

func getCurentFilePath(_ file: StaticString = #file) -> URL {
  return URL(fileURLWithPath: file.description, isDirectory: false)
    .deletingLastPathComponent()
}

extension FileManager {
  func contentsOfDirectory(at url: URL) throws -> [URL] {
    return try contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: nil,
      options: []
    )
  }
}

class WKWebViewSnapshoter {
  private class WKDelegate: NSObject, WKNavigationDelegate {
    private var onNavigationFinishCallbacks = [() -> Void]()

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
      let callbacks = onNavigationFinishCallbacks
      onNavigationFinishCallbacks.removeAll()
      callbacks.forEach(apply)
    }

    func onNavigationFinish(_ callback: @escaping () -> Void) {
      onNavigationFinishCallbacks.append(callback)
    }
  }

  private let webView = WKWebView()
  private let delegate = WKDelegate()

  init() {
    webView.navigationDelegate = delegate
    webView.layer?.contentsScale = 1
  }

  func take(
    html: String,
    viewport: CGRect
  ) throws -> NSImage {
    let origin = viewport.origin
    let size = modified(viewport.size) {
      $0.width += origin.x * 2
      $0.height += origin.y * 2
    }
    webView.frame = .init(origin: .zero, size: size)
    webView.bounds = viewport
    let config = WKSnapshotConfiguration()
    config.snapshotWidth = NSNumber(value: Double(viewport.size.width * 10))

    webView.loadHTMLString(html, baseURL: nil)
    waitCallbackOnMT(delegate.onNavigationFinish)

    let result = waitCallbackOnMT { [webView] completion in
      doAfterNextPresentationUpdate {
        webView.takeSnapshot(with: config) {
          completion(($0, $1))
        }
      }
    }
    return try result.0 !! (result.1 ?? Error.unknownSnapshotError)
  }

  private func doAfterNextPresentationUpdate(
    _ block: @escaping @convention(block) () -> Void
  ) {
    webView.perform(Selector(("_doAfterNextPresentationUpdate:")), with: block)
  }
}

func saveImage(_ image: NSImage, atUrl url: URL) {
  try? FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true,
    attributes: nil
  )
  guard
    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
  else { fatalError() } // TODO: handle error
  let newRep = NSBitmapImageRep(cgImage: cgImage)
  newRep.size = image.size // if you want the same size
  guard
    let pngData = newRep.representation(using: .png, properties: [:])
  else { fatalError() } // TODO: handle error
  do {
    try pngData.write(to: url)
  } catch {
    print("error saving: \(error)")
  }
}
