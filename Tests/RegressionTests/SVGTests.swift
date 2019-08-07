import Base
import libcggen
import WebKit
import XCTest

class SVGTest: XCTestCase {
  func testSnapshotsNotFlacking() throws {
    let snapshot = WKWebViewSnapshoter()
    let blackPixel = RGBAPixel(bufferPiece: [.zero, .zero, .zero, .max])
    let size = 20
    measure {
      let snapshot = try! snapshot.take(
        html: blackSquareHTML(size: size),
        viewport: .init(origin: .zero, size: .square(CGFloat(size)))
      ).cgimg()
      let buffer = RGBABuffer(image: snapshot)
      XCTAssert(buffer.pixels.allSatisfy {
        $0.allSatisfy { $0 == blackPixel }
      })
    }
  }

  func testSimpliestSVG() {
    test(svg: "fill")
  }
}

private func blackSquareHTML(size: Int) -> String {
  let fsize = SVG.Float(size)
  let svgSize = SVG.Length(fsize)
  let blackRect = SVG.rect(.init(
    x: 0, y: 0,
    width: svgSize, height: svgSize,
    presentation: .init(fill: .rgb(.black()), fillOpacity: 1)
  ))
  let svg = SVG.Document(
    width: svgSize, height: svgSize, viewBox: .init(0, 0, fsize, fsize),
    children: [blackRect]
  )

  let svgHTML = renderXML(from: svg)
  let style = XML.el("style", attrs: ["type": "text/css"], children: [
    .text("html, body {width:100%;height: 100%;margin: 0px;padding: 0px;}"),
  ])
  return XML.el("html", children: [style, svgHTML]).render()
}

private func test(svg name: String, tolerance: Double = 0.01) {
  XCTAssertNoThrow(try {
    let svg = sample(named: name)
    let referenceImg = try WKWebViewSnapshoter()
      .take(sample: svg, scale: 1).cgimg()

    let images = try cggen(files: [svg])
    XCTAssertEqual(images.count, 1)
    let image = images[0]
    XCTAssertEqual(referenceImg.intSize, image.intSize)
    let diff = compare(referenceImg, image)

    XCTAssertLessThan(diff, tolerance)
  }())
}

private func sample(named name: String) -> URL {
  return samplesPath.appendingPathComponent(name).appendingPathExtension("svg")
}

private let samplesPath =
  getCurentFilePath().appendingPathComponent("svg_samples")

private class WKWebViewSnapshoter {
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
  }

  func take(
    html: String,
    viewport: CGRect
  ) throws -> NSImage {
    enum Error: Swift.Error {
      case unknownSnapshotError
    }
    let contentScale = webView.layer.map(\.contentsScale) ?? 1
    let origin = viewport.origin
    let size = modified(viewport.size) {
      $0.width += origin.x * 2
      $0.height += origin.y * 2
    }
    webView.frame = .init(origin: .zero, size: size)
    webView.bounds = viewport
    let config = WKSnapshotConfiguration()
    config.snapshotWidth = NSNumber(value: Double(viewport.size.width / contentScale))

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

extension WKWebViewSnapshoter {
  func take(sample: URL, scale _: CGFloat) throws -> NSImage {
    return try take(
      html: String(contentsOf: sample),
      viewport: .init(x: 8, y: 8, width: 50, height: 50)
    )
  }
}
