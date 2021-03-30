import os.log
import WebKit
import XCTest

import Base
import libcggen

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

  func testCapsJoins() {
    test(svg: "caps_joins")
  }

  func testDashes() {
    test(svg: "dashes")
  }

  func testColorNames() {
    test(svg: "colornames", size: .init(width: 120, height: 130))
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

  func testTransforms() {
    test(svg: "transforms")
  }

  func testTopmostPresentationAttributes() throws {
    // FIXME: WKWebView acting strange on github ci
    try XCTSkipIf(
      ProcessInfo().environment["GITHUB_ACTION"] != nil,
      "test fails on github actions"
    )
    test(svg: "topmost_presentation_attributes")
  }
}

class SVGPathTests: XCTestCase {
  func testMoveToCommands() {
    test(svg: "path_move_to_commands")
  }

  func testComplexCurve() {
    test(svg: "path_complex_curve")
  }

  func testCircleCommands() {
    test(svg: "path_circle_commands")
  }

  func testShortCommands() {
    test(svg: "path_short_commands")
  }

  func testRelativeCommands() {
    test(svg: "path_relative_commands")
  }

  func testSmoothCurve() {
    test(svg: "path_smooth_curve")
  }

  func testFillRule() {
    test(svg: "path_fill_rule")
  }

  func testPathFillRuleNonzeroDefault() {
    test(svg: "path_fill_rule_nonzero_default")
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

  func testGradientOpacity() {
    test(svg: "gradient_opacity")
  }
}

class SVGShadowTests: XCTestCase {
  func testSimpleShadow() {
    test(svg: "simple_shadow", tolerance: 0.019)
  }

  func testDifferentBlurRadiuses() {
    test(svg: "different_blur_radius", tolerance: 0.022)
  }
}

// Sometimes it is usefull to pass some arbitrary svg to check that it is
// correctly handled.
class SVGCustomCheckTests: XCTestCase {
  static let sizeParser: Parser<Substring, CGSize> =
    (int() <<~ "x" ~ int()).map(CGSize.init)
  func testSvgFromArgs() throws {
    let args = CommandLine.arguments
    guard let path = args[safe: 1].map(URL.init(fileURLWithPath:)),
          let size = args[safe: 2].flatMap(Self.sizeParser.whole >>> \.value)
    else { throw XCTSkip() }
    print("Checking svg at \(path.path)")
    test(svg: path, size: size)
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

private let defaultTolerance = 0.002
private let defaultScale = 2.0

private func test(
  svg name: String,
  tolerance: Double = defaultTolerance,
  scale: Double = defaultScale,
  size: CGSize = CGSize(width: 50, height: 50)
) {
  test(
    svg: sample(named: name),
    tolerance: tolerance,
    scale: scale, size: size
  )
}

private func test(
  svg path: URL,
  tolerance: Double = defaultTolerance,
  scale: Double = defaultScale,
  size: CGSize
) {
  XCTAssertNoThrow(try {
    try test(
      snapshot: {
        try WKWebViewSnapshoter()
          .take(sample: $0, scale: CGFloat(scale), size: size).cgimg()
      },
      adjustImage: {
        // Unfortunately, snapshot from web view always comes with white
        // background color
        $0.redraw(with: .white)
      },
      antialiasing: true,
      path: path,
      tolerance: tolerance,
      scale: scale,
      size: size
    )
  }())
}

private func sample(named name: String) -> URL {
  samplesPath.appendingPathComponent(name).appendingPathExtension("svg")
}

private let samplesPath =
  getCurentFilePath().appendingPathComponent("svg_samples")

extension WKWebView {
  @NSManaged
  private func _setPageZoomFactor(_: Double)
  @NSManaged
  private func _pageZoomFactor() -> Double

  fileprivate var pageZoomFactor: CGFloat {
    get {
      if #available(macOS 11, *) {
        return pageZoom
      } else {
        return CGFloat(_pageZoomFactor())
      }
    }
    set {
      if #available(macOS 11, *) {
        pageZoom = newValue
      } else {
        _setPageZoomFactor(Double(newValue))
      }
    }
  }
}

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
    let contentScale = webView.layer.map(\.contentsScale) ?? 1
    let effectiveScale = scale / contentScale
    let effectiveViewport = viewport.applying(.scale(effectiveScale))
    let origin = effectiveViewport.origin
    let size = modified(effectiveViewport.size) {
      $0.width += origin.x * 2
      $0.height += origin.y * 2
    }
    let frame = CGRect(origin: .zero, size: size)
    webView.frame = frame
    webView.bounds = frame
    webView.pageZoomFactor = scale / contentScale

    let config = WKSnapshotConfiguration()
    config.rect = effectiveViewport

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
    try take(
      html: String(contentsOf: sample),
      viewport: CGRect(origin: CGPoint(x: 8, y: 8), size: size),
      scale: scale
    )
  }
}
