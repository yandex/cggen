import os.log
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

  func testMergedBytecode() {
    test(
      paths: [
        sample(named: "fill"),
        sample(named: "lines"),
        sample(named: "alpha"),
        sample(named: "group_opacity"),
        sample(named: "shapes"),
        sample(named: "caps_joins"),
        sample(named: "dashes"),
        sample(named: "use_tag"),
        sample(named: "use_referencing_not_in_defs"),
        sample(named: "simple_mask"),
        sample(named: "clip_path"),
        sample(named: "transforms")
      ]
    )
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

  func testPathFillRuleGstate() {
    test(svg: "path_fill_rule_gstate")
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
    test(svg: "shadow_simple", tolerance: 0.019)
  }

  func testShadowColors() {
    test(svg: "shadow_colors", tolerance: 0.016)
  }

  func testDifferentBlurRadiuses() {
    test(svg: "shadow_blur_radius", tolerance: 0.022)
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

class PathExtractionTests: XCTestCase {
  func testLinesAndCurves() {
    test(args: linesAndCurvesArgs)
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
  svg: String,
  tolerance: Double = defaultTolerance,
  scale: CGFloat = defaultScale,
  size: CGSize = CGSize(width: 50, height: 50)
) {
  test(
    svg: sample(named: svg),
    tolerance: tolerance,
    scale: scale,
    size: size
  )
}

private func test(
  svg: URL,
  tolerance: Double = defaultTolerance,
  scale: CGFloat = defaultScale,
  size: CGSize
) {
  XCTAssertNoThrow(try testBC(
    path: svg,
    referenceRenderer: {
      try WKWebViewSnapshoter().take(sample: $0, scale: scale, size: size)
        .cgimg()
    },
    scale: scale,
    resultAdjust: { $0.redraw(with: .white) },
    tolerance: tolerance
  ))
}

private func test(
  paths: [URL],
  tolerance: Double = defaultTolerance,
  scale: CGFloat = defaultScale,
  size: CGSize = CGSize(width: 50, height: 50)
) {
  XCTAssertNoThrow(try testMBC(
    paths: paths,
    referenceRenderer: {
      try WKWebViewSnapshoter().take(sample: $0, scale: scale, size: size)
        .cgimg()
    },
    scale: scale,
    resultAdjust: { $0.redraw(with: .white) },
    tolerance: tolerance
  ))
}

private func test(
  args: PathTestArguments
) {
  try? testPathExtraction(
    path: CGPath.from(args.segments),
    svg: sample(named: args.svgName)
  )
}

private func sample(named name: String) -> URL {
  svgSamplesPath.appendingPathComponent(name).appendingPathExtension("svg")
}

let svgSamplesPath =
  getCurentFilePath().appendingPathComponent("svg_samples")

typealias PathTestArguments = (svgName: String, segments: [PathSegment])

let linesAndCurvesArgs: PathTestArguments = (
  svgName: "lines_and_curves",
  segments: [
    .moveTo(CGPoint(x: 0, y: 1)),
    .lineTo(CGPoint(x: 2, y: 2)),
    .lineTo(CGPoint(x: 5, y: 2)),
    .lineTo(CGPoint(x: 5, y: -4)),
    .curveTo(
      CGPoint(x: 3, y: -4),
      CGPoint(x: 4, y: -8),
      CGPoint(x: 0, y: -7)
    ),
    .curveTo(
      CGPoint(x: -4, y: -6),
      CGPoint(x: -1, y: -14),
      CGPoint(x: -7, y: -10)
    ),
    .addArc(
      center: CGPoint(x: -7, y: -5),
      radius: 5,
      startAngle: -.pi / 2,
      endAngle: .pi / 2,
      clockwise: true
    ),
    .lineTo(CGPoint(x: 0, y: 1)),
  ]
)
