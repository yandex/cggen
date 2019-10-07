import Base
import libcggen
import WebKit
import XCTest

let failedSnapshotsDirKey = "FAILED_SNAPSHOTS_DIR"

class SVGTest: XCTestCase {
  func testSnapshotsNotFlacking() throws {
    let snapshot = WKWebViewSnapshoter()
    let blackPixel = RGBAPixel(bufferPiece: [.zero, .zero, .zero, .max])
    let size = 20
    measure {
      let snapshot = try! snapshot.take(
        html: blackSquareHTML(size: size),
        viewport: .init(origin: .zero, size: .square(CGFloat(size))),
        scale: 1
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

  func testLines() {
    test(svg: "lines")
  }

  func testAlpha() {
    test(svg: "alpha")
  }

  func testGroupOpacity() {
    test(svg: "group_opacity")
  }

  func testShapes() {
    test(svg: "shapes")
  }

  func testComplexCurve() {
    test(svg: "complex_curve")
  }

  func testCapsJoins() {
    test(svg: "caps_joins")
  }

  func testDashes() {
    test(svg: "dashes")
  }

  func testColorNames() {
    test(svg: "colornames", tolerance: 0.001, size: .init(width: 120, height: 130))
  }

  func testCurveShortCommands() {
    test(svg: "curve_short_commands")
  }

  func testUseTag() {
    test(svg: "use_tag")
  }

  func testUseReferencingNotInDefs() {
    test(svg: "use_referencing_not_in_defs")
  }

  func testSimpleMask() {
    test(svg: "simple_mask")
  }

  func testClipPath() {
    test(svg: "clip_path")
  }
}

class SVGGradientTests: XCTestCase {
  func testGradient() {
    test(svg: "gradient")
  }

  func testGradientShape() {
    test(svg: "gradient_shape")
  }

  func testGradientStroke() {
    test(svg: "gradient_stroke")
  }

  func testGradientFillStrokeCombinations() {
    test(svg: "gradient_fill_stroke_combinations")
  }

  func testGradientRelative() {
    test(svg: "gradient_relative")
  }

  func testGradientWithAlpha() {
    test(svg: "gradient_with_alpha")
  }

  func testGradientThreeControlPoints() {
    test(svg: "gradient_three_dots")
  }

  func testGradientWithMask() {
    test(svg: "gradient_with_mask")
  }

  func testGradientRadial() {
    test(svg: "gradient_radial")
  }

  func testGradientUnits() {
    test(svg: "gradient_units")
  }

  func testGradientAbsoluteStartEnd() {
    test(svg: "gradient_absolute_start_end")
  }
}

class SVGShadowTests: XCTestCase {
  func testSimpleShadow() {
    test(svg: "simple_shadow")
  }
}

private func blackSquareHTML(size: Int) -> String {
  let fsize = SVG.Float(size)
  let svgSize = SVG.Length(fsize)
  let blackRect = SVG.rect(.init(
    core: .init(id: nil),
    presentation: .construct {
      $0.fill = .rgb(.black())
      $0.fillOpacity = 1
    },
    transform: nil,
    data: .init(x: 0, y: 0, rx: nil, ry: nil, width: svgSize, height: svgSize)
  ))
  let svg = SVG.Document(
    core: .init(id: nil),
    presentation: .empty,
    width: svgSize, height: svgSize, viewBox: .init(0, 0, fsize, fsize),
    children: [blackRect]
  )

  let svgHTML = renderXML(from: svg)
  let style = XML.el("style", attrs: ["type": "text/css"], children: [
    .text("html, body {width:100%;height: 100%;margin: 0px;padding: 0px;}"),
  ])
  return XML.el("html", children: [style, svgHTML]).render()
}

private func test(
  svg name: String,
  tolerance: Double = 0.01,
  scale: Double = 2,
  size: CGSize = CGSize(width: 50, height: 50),
  file: StaticString = #file, line: UInt = #line
) {
  XCTAssertNoThrow(try {
    let svg = sample(named: name)
    let referenceImg = try WKWebViewSnapshoter()
      .take(sample: svg, scale: CGFloat(scale), size: size).cgimg()

    let images = try cggen(files: [svg], scale: scale)
    XCTAssertEqual(images.count, 1, file: file, line: line)
    // Unfortunately, snapshot from web view always comes with white
    // background color
    let image = images[0].redraw(with: .white)
    XCTAssertEqual(referenceImg.intSize, image.intSize, file: file, line: line)
    let diff = compare(referenceImg, image)

    XCTAssertLessThan(
      diff, tolerance, "Calculated diff exceeds tolerance",
      file: file, line: line
    )
    if diff >= tolerance {
      XCTContext.runActivity(named: "Attached Failure Diff of \(name)") {
        $0.add(.init(image: image))
        $0.add(.init(image: referenceImg))
      }
    }
  }(), file: file, line: line)
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
    viewport: CGRect,
    scale: CGFloat
  ) throws -> NSImage {
    enum Error: Swift.Error {
      case unknownSnapshotError
    }
    let contentScale = webView.layer.map(^\.contentsScale) ?? 1
    let origin = viewport.origin
    let size = modified(viewport.size) {
      $0.width += origin.x * 2
      $0.height += origin.y * 2
    }
    webView.frame = .init(origin: .zero, size: size)
    webView.bounds = viewport
    let config = WKSnapshotConfiguration()
    config.snapshotWidth = NSNumber(value: Double(viewport.size.width * scale / contentScale))

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
  func take(sample: URL, scale: CGFloat, size: CGSize) throws -> NSImage {
    return try take(
      html: String(contentsOf: sample),
      viewport: CGRect(origin: CGPoint(x: 8, y: 8), size: size),
      scale: scale
    )
  }
}

extension XCTAttachment {
  convenience init(image: CGImage) {
    let size = NSSize(width: image.width, height: image.height)
    let nsimage = NSImage(cgImage: image, size: size)
    self.init(image: nsimage)
  }
}
