// NOTE: SVG tests remain in XCTest due to WebKit integration issues
//
// The SVG tests use WKWebViewSnapshoter which depends on WebKit's navigation
// callbacks and RunLoop.current.spin() for synchronous waiting. This
// architecture is incompatible with Swift Testing's execution model:
//
// - XCTest: Runs tests on main thread with active RunLoop
// - Swift Testing: Different execution context, RunLoop.current.spin() hangs
//
// The WebKit navigation callbacks (waitCallbackOnMT) never complete in
// Swift Testing, causing tests to hang indefinitely. To fix this would
// require rewriting the WebKit testing infrastructure to use async/await.
//
// PathExtractionTests were successfully migrated as they don't use WebKit.

import os.log
import Testing
import XCTest

import Base
import CGGenCLI
import CGGenIR
import CGGenRuntime
@_spi(Testing) import CGGenRTSupport

import Parsing
import SVGParse

class SVGTest: XCTestCase {
  @MainActor
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
        sample(named: "transforms"),
      ]
    )
  }

  func testBytecodeDeterminism() throws {
    // Load SVG with multiple gradients
    let svgData =
      try Data(contentsOf: sample(named: "gradient_determinism_test"))

    // Generate bytecode multiple times
    var bytecodes: [[UInt8]] = []

    // Generate 10 times to catch any nondeterminism
    for _ in 0..<10 {
      // Parse SVG
      let document = try SVGParser.root(from: svgData)

      // Convert to draw route
      let routines = try SVGToDrawRouteConverter.convert(document: document)
      let drawRoute = routines.drawRoutine

      // Generate bytecode
      let bytecode = generateRouteBytecode(route: drawRoute)
      bytecodes.append(bytecode)
    }

    // All bytecodes should be identical
    let firstBytecode = bytecodes[0]
    for (index, bytecode) in bytecodes.enumerated() {
      XCTAssertEqual(
        bytecode,
        firstBytecode,
        "Bytecode at index \(index) differs from first"
      )
    }
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

  func testQuadraticBezierCommands() {
    test(svg: "path_quadratic_bezier")
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

  func testLinearGradientTransform() {
    test(svg: "gradient_transform_linear")
  }

  func testRadialGradientTransform() {
    test(svg: "gradient_transform_radial")
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
  nonisolated(unsafe)
  static let sizeParser = Parse(input: Substring.self) {
    Int.parser()
    "x"
    Int.parser()
  }.map(CGSize.init)
  func testSvgFromArgs() throws {
    let args = CommandLine.arguments
    guard let path = args[safe: 1].map(URL.init(fileURLWithPath:)),
          let size = args[safe: 2].flatMap({ try? Self.sizeParser.parse($0) })
    else { throw XCTSkip() }
    print("Checking svg at \(path.path)")
    test(svg: path, size: size)
  }
}

@Suite struct PathExtractionTests {
  @Test func linesAndCurves() {
    test(args: linesAndCurvesArgs)
  }
}

// MARK: - Two-Mode Test Architecture

import SnapshotTesting

enum SVGTestCase: String, CaseIterable {
  case fill
  case lines
  case alpha
  case group_opacity
  case shapes
  case caps_joins
  case miter_limit
  case dashes
  case colornames
  case use_tag
  case use_referencing_not_in_defs
  case simple_mask
  case clip_path
  case transforms
  case topmost_presentation_attributes
}

extension SVGTestCase {
  var size: CGSize {
    switch self {
    case .colornames:
      CGSize(width: 120, height: 130)
    default:
      CGSize(width: 50, height: 50)
    }
  }
}

// MARK: - CGGen Tests Against WebKit References

@Test private func fill() { check(.fill) }
@Test private func lines() { check(.lines) }
@Test private func alpha() { check(.alpha) }
@Test private func groupOpacity() { check(.group_opacity) }
@Test private func shapes() { check(.shapes) }
@Test private func capsJoins() { check(.caps_joins) }
@Test private func miterLimit() { check(.miter_limit) }
@Test private func dashes() { check(.dashes) }
@Test private func colorNames() { check(.colornames) }
@Test private func useTag() { check(.use_tag) }
@Test private func useReferencingNotInDefs() {
  check(.use_referencing_not_in_defs)
}

@Test private func simpleMask() { check(.simple_mask) }
@Test private func clipPath() { check(.clip_path) }
@Test private func transforms() { check(.transforms) }
@Test private func topmostPresentationAttributes() {
  check(.topmost_presentation_attributes)
}

// MARK: - WebKit Reference Generation

extension SVGTest {
  @MainActor
  func testWebKit() throws {
    // Skip unless explicitly enabled via environment variable
    try XCTSkipUnless(
      extendedTestsEnabled,
      "WebKit reference generation tests are disabled by default. Set CGGEN_EXTENDED_TESTS=1 to run them."
    )

    // Generate WebKit reference snapshots for all test cases
    for testCase in SVGTestCase.allCases {
      let snapshot = WKWebViewSnapshoter()
      let webkitImage = try snapshot.take(
        sample: sample(named: testCase.rawValue),
        scale: 2.0,
        size: testCase.size
      )

      let cgImage = try webkitImage.cgimg().redraw(with: .white)

      SnapshotTesting.assertSnapshot(
        of: cgImage,
        as: .cgImage(),
        named: testCase.rawValue,
        testName: "webkit-references"
      )
    }
  }
}

// MARK: - Helper Functions

private func check(
  _ testCase: SVGTestCase,
  tolerance: Double = 0.002
) {
  SnapshotTesting.withSnapshotTesting(record: .never) {
    let bytecode = try! getImageBytecode(from: sample(named: testCase.rawValue))
    let cggenImage = try! renderBytecode(
      bytecode,
      width: Int(testCase.size.width * 2.0),
      height: Int(testCase.size.height * 2.0),
      scale: 2.0
    ).redraw(with: .white)

    assertSnapshot(
      of: cggenImage,
      as: .cgImage(precision: 1.0 - tolerance),
      named: testCase.rawValue,
      file: #filePath,
      testName: "webkit-references"
    )
  }
}

private func sample(named name: String) -> URL {
  svgSamplesPath.appendingPathComponent(name).appendingPathExtension("svg")
}

private func blackSquareHTML(size: Int) -> String {
  """
  <html>
  <style type="text/css">html, body {width:100%;height: 100%;margin: 0px;padding: 0px;}</style>
  <svg width="\(size)" height="\(size)" viewBox="0 0 \(size) \(size)">
  <rect x="0" y="0" width="\(size)" height="\(size)" \
  fill="#000000" fill-opacity="1"/>
  </svg>
  </html>
  """
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
  XCTAssertNoThrow(try MainActor.assumeIsolated {
    try testBC(
      path: svg,
      referenceRenderer: {
        try WKWebViewSnapshoter().take(sample: $0, scale: scale, size: size)
          .cgimg()
      },
      scale: scale,
      resultAdjust: { $0.redraw(with: .white) },
      tolerance: tolerance
    )
  })
}

private func test(
  paths: [URL],
  tolerance: Double = defaultTolerance,
  scale: CGFloat = defaultScale,
  size: CGSize = CGSize(width: 50, height: 50)
) {
  XCTAssertNoThrow(try MainActor.assumeIsolated {
    try testMBC(
      paths: paths,
      referenceRenderer: {
        try WKWebViewSnapshoter().take(sample: $0, scale: scale, size: size)
          .cgimg()
      },
      scale: scale,
      resultAdjust: { $0.redraw(with: .white) },
      tolerance: tolerance
    )
  })
}

private func test(
  args: PathTestArguments
) {
  try? testPathExtraction(
    path: CGPath.from(args.segments),
    svg: sample(named: args.svgName)
  )
}

let svgSamplesPath =
  getCurrentFilePath().appendingPathComponent("svg_samples")

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

// MARK: - Snapshot Testing Utilities

// Check if extended tests (like WebKit reference generation) should run
let extendedTestsEnabled = ProcessInfo.processInfo
  .environment["CGGEN_EXTENDED_TESTS"] == "1"

extension Snapshotting where Value == CGImage, Format == CGImage {
  static func cgImage(precision: Double = 0.998) -> Snapshotting {
    Snapshotting(
      pathExtension: "png",
      diffing: .init(
        toData: { cgImage in
          let imageRep = NSBitmapImageRep(cgImage: cgImage)
          return imageRep.representation(using: .png, properties: [:])!
        },
        fromData: { data in
          guard let dataProvider = CGDataProvider(data: data as CFData),
                let cgImage = CGImage(
                  pngDataProviderSource: dataProvider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
                ) else {
            fatalError("Failed to create CGImage from PNG data")
          }
          return cgImage
        },
        diff: { reference, actual in
          guard reference.width == actual.width,
                reference.height == actual.height else {
            return ("Images have different sizes", [])
          }

          let diff = compare(reference, actual)
          let actualPrecision = 1.0 - diff

          if actualPrecision >= precision {
            return nil
          }

          let nsRef = NSImage(
            cgImage: reference,
            size: NSSize(width: reference.width, height: reference.height)
          )
          let nsActual = NSImage(
            cgImage: actual,
            size: NSSize(width: actual.width, height: actual.height)
          )
          let nsDiff = NSImage(
            cgImage: CGImage.diff(lhs: reference, rhs: actual),
            size: NSSize(width: reference.width, height: reference.height)
          )

          let message =
            "Actual image precision \(actualPrecision) is less than required \(precision)"

          let attachments = [
            XCTAttachment(image: nsRef),
            XCTAttachment(image: nsActual),
            XCTAttachment(image: nsDiff),
          ]

          return (message, attachments)
        }
      )
    ) { $0 }
  }
}
