import AppKit
import Foundation
import os.log
import Testing

import CGGenCLI
import CGGenCore
import CGGenIR
@_spi(Testing) import CGGenRTSupport

import Parsing

// Sometimes it is useful to pass some arbitrary svg to check that it is
// correctly handled.
@Suite struct SVGCustomCheckTests {
  nonisolated(unsafe)
  static let sizeParser = Parse(input: Substring.self) {
    Int.parser()
    "x"
    Int.parser()
  }.map(CGSize.init)

  @MainActor
  @Test func svgFromArgs() async throws {
    let args = CommandLine.arguments
    guard let path = args[safe: 1].map(URL.init(fileURLWithPath:)),
          let _ = args[safe: 2].flatMap({ try? Self.sizeParser.parse($0) })
    else {
      // Skip test if no arguments provided
      return
    }
    print("Checking svg at \(path.path)")

    // Custom command-line test using WebKitSVG2PNG
    let svgData = try Data(contentsOf: path)
    let svgString = String(data: svgData, encoding: .utf8) ?? ""

    let converter = WebKitSVG2PNG()
    _ = try await converter.convertToCGImage(
      svg: svgString,
      scale: 2.0
    )
    .redraw(with: .white)

    // Generate bytecode version
    let cggenImage = try renderSVGToBitmap(from: path, scale: 2.0)

    // Compare images using SnapshotTesting's built-in comparison
    SnapshotTesting.withSnapshotTesting(record: .never) {
      assertSnapshot(
        of: cggenImage,
        as: .cgImage(tolerance: 0.002),
        named: "custom-svg",
        record: false
      )
    }
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
  case nested_transparent_group
  // Path tests
  case path_move_to_commands
  case path_complex_curve
  case path_circle_commands
  case path_short_commands
  case path_relative_commands
  case path_smooth_curve
  case path_fill_rule
  case path_fill_rule_nonzero_default
  case path_fill_rule_gstate
  case path_quadratic_bezier
  // Gradient tests
  case gradient
  case gradient_shape
  case gradient_stroke
  case gradient_fill_stroke_combinations
  case gradient_relative
  case gradient_with_alpha
  case gradient_three_dots
  case gradient_transform_linear
  case gradient_transform_radial
  case gradient_with_mask
  case gradient_radial
  case gradient_units
  case gradient_absolute_start_end
  case gradient_opacity
  // Shadow tests
  case shadow_simple
  case shadow_colors
  case shadow_blur_radius
  // Additional test files
  case gradient_determinism_test
  case lines_and_curves
  case paths_and_images
  case underlying_object_with_tiny_alpha
  case white_cross_scn_operator
}

extension SVGTestCase {
  var tolerance: Double {
    switch self {
    case .shadow_blur_radius:
      0.022
    default:
      0.02
    }
  }

  // Smoke test subset - a representative selection of test cases
  // for quick verification in compilation and runtime tests
  static let smokeTestSubset: [SVGTestCase] = [
    .caps_joins,
    .clip_path,
    .dashes,
    .shadow_blur_radius,
    .fill,
    .gradient,
    .lines,
    .shapes,
    .transforms,
  ]
}

// MARK: - CGGen Tests Against WebKit References

@Suite struct SVGTests {
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

  @Test private func nestedTransparentGroup() {
    check(.nested_transparent_group)
  }

  // MARK: - Path Tests

  @Test private func pathMoveToCommands() { check(.path_move_to_commands) }
  @Test private func pathComplexCurve() { check(.path_complex_curve) }
  @Test private func pathCircleCommands() { check(.path_circle_commands) }
  @Test private func pathShortCommands() { check(.path_short_commands) }
  @Test private func pathRelativeCommands() { check(.path_relative_commands) }
  @Test private func pathSmoothCurve() { check(.path_smooth_curve) }
  @Test private func pathFillRule() { check(.path_fill_rule) }
  @Test private func pathFillRuleNonzeroDefault() {
    check(.path_fill_rule_nonzero_default)
  }

  @Test private func pathFillRuleGstate() { check(.path_fill_rule_gstate) }
  @Test private func pathQuadraticBezier() { check(.path_quadratic_bezier) }

  // MARK: - Gradient Tests

  @Test private func gradient() { check(.gradient) }
  @Test private func gradientShape() { check(.gradient_shape) }
  @Test private func gradientStroke() { check(.gradient_stroke) }
  @Test private func gradientFillStrokeCombinations() {
    check(.gradient_fill_stroke_combinations)
  }

  @Test private func gradientRelative() { check(.gradient_relative) }
  @Test private func gradientWithAlpha() { check(.gradient_with_alpha) }
  @Test private func gradientThreeControlPoints() {
    check(.gradient_three_dots)
  }

  @Test private func linearGradientTransform() {
    check(.gradient_transform_linear)
  }

  @Test private func radialGradientTransform() {
    check(.gradient_transform_radial)
  }

  @Test private func gradientWithMask() { check(.gradient_with_mask) }
  @Test private func gradientRadial() { check(.gradient_radial) }
  @Test private func gradientUnits() { check(.gradient_units) }
  @Test private func gradientAbsoluteStartEnd() {
    check(.gradient_absolute_start_end)
  }

  @Test private func gradientOpacity() { check(.gradient_opacity) }

  // MARK: - Shadow Tests

  @Test private func simpleShadow() { check(.shadow_simple) }
  @Test private func shadowColors() { check(.shadow_colors) }
  @Test private func differentBlurRadiuses() { check(.shadow_blur_radius) }

  // MARK: - Additional Tests

  @Test private func gradientDeterminismTest() {
    check(.gradient_determinism_test)
  }

  @Test private func linesAndCurvesTest() { check(.lines_and_curves) }
  @Test private func pathsAndImages() { check(.paths_and_images) }
  @Test private func underlyingObjectWithTinyAlpha() {
    check(.underlying_object_with_tiny_alpha)
  }

  @Test private func whiteCrossScnOperator() { check(.white_cross_scn_operator)
  }

  // MARK: - Merged Bytecode Tests

  @Test private func mergedBytecodeAgainstSnapshots() throws {
    let testCases = SVGTestCase.allCases

    let svgPaths = testCases.map { sample(named: $0.rawValue) }
    let (
      mergedBytecode,
      positions,
      decompressedSize,
      dimensions
    ) = try getImagesMergedBytecodeAndPositions(from: svgPaths)

    for ((testCase, position), size) in zip(
      zip(testCases, positions),
      dimensions
    ) {
      let width = Int(size.width * 2.0)
      let height = Int(size.height * 2.0)

      guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
        throw Err("Failed to create CGContext")
      }

      context.concatenate(CGAffineTransform(scaleX: 2.0, y: 2.0))
      context.setAllowsAntialiasing(true)

      try runMergedBytecode(
        fromData: Data(mergedBytecode),
        context,
        decompressedSize,
        position.0,
        position.1
      )

      guard let image = context.makeImage() else {
        throw Err("Failed to make image from context")
      }

      // Use the same snapshot name as individual tests
      assertAgainstReference(
        image: image.redraw(with: .white),
        testCase: testCase
      )
    }
  }
}

// MARK: - WebKit Reference Generation

@Suite(.enabled(if: extendedTestsEnabled))
struct SVGReferencesTests {
  @MainActor
  @Test("Generate WebKit reference snapshots", arguments: SVGTestCase.allCases)
  func allCases(testCase: SVGTestCase) async throws {
    let svgPath = sample(named: testCase.rawValue)
    let svgData = try Data(contentsOf: svgPath)
    let svgString = String(data: svgData, encoding: .utf8) ?? ""

    let converter = WebKitSVG2PNG()
    let cgImage = try await converter.convertToCGImage(
      svg: svgString,
      scale: 2.0
    ).redraw(with: .white)

    withSnapshotTesting(diffTool: .noop) {
      assertReferenceSnapshot(of: cgImage, testCase: testCase, tolerance: 0.002)
    }
  }
}

// MARK: - Helper Functions

private func check(_ testCase: SVGTestCase) {
  let svgPath = sample(named: testCase.rawValue)
  let cggenImage = try! renderSVGToBitmap(from: svgPath, scale: 2.0)

  assertAgainstReference(
    image: cggenImage,
    testCase: testCase
  )
}

private func renderSVGToBitmap(
  from svgPath: URL,
  scale: CGFloat
) throws -> CGImage {
  let (bytecode, size) = try getImageBytecode(from: svgPath)
  return try renderBytecode(
    bytecode,
    width: Int(size.width * scale),
    height: Int(size.height * scale),
    scale: scale
  ).redraw(with: .white)
}

extension SnapshotTestingConfiguration.DiffTool {
  static let noop = Self { _, _ in "" }
}

private func assertReferenceSnapshot(
  of image: CGImage,
  testCase: SVGTestCase,
  tolerance: Double? = nil
) {
  if let debugURL = testDebugOutputDir {
    let snapshotPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent("SVGTests")
      .appendingPathComponent("webkit-references.\(testCase.rawValue).png")

    // Try to load reference image for comparison
    if let referenceData = try? Data(contentsOf: snapshotPath),
       let dataProvider = CGDataProvider(data: referenceData as CFData),
       let referenceImage = CGImage(
         pngDataProviderSource: dataProvider,
         decode: nil,
         shouldInterpolate: true,
         intent: .defaultIntent
       ) {
      // Compare images
      let diff = SnapshotTestingSupport.compare(referenceImage, image)
      let tolerance = testCase.tolerance

      // Save debug output if test would fail
      if diff >= tolerance {
        saveTestFailureArtifacts(
          testName: testCase.rawValue,
          reference: referenceImage,
          result: image,
          diff: diff,
          tolerance: tolerance,
          to: debugURL
        )
      }
    }
  }

  assertSnapshot(
    of: image,
    as: .cgImage(tolerance: tolerance ?? testCase.tolerance),
    named: testCase.rawValue,
    file: svgTestsFilePath,
    testName: "webkit-references"
  )
}

func assertAgainstReference(
  image: CGImage,
  testCase: SVGTestCase
) {
  SnapshotTesting.withSnapshotTesting(record: .never, diffTool: .noop) {
    assertReferenceSnapshot(of: image, testCase: testCase)
  }
}

private func sample(named name: String) -> URL {
  svgSamplesPath.appendingPathComponent(name).appendingPathExtension("svg")
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

// MARK: - Test Coverage Verification

@Test private func allSVGFilesHaveTestCases() throws {
  // Get all SVG files in the svg_samples directory
  let svgSamplesURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("svg_samples")

  let fileManager = FileManager.default
  let svgFiles = try fileManager.contentsOfDirectory(
    at: svgSamplesURL,
    includingPropertiesForKeys: nil
  )
  .filter { $0.pathExtension == "svg" }
  .map { $0.deletingPathExtension().lastPathComponent }
  .sorted()

  // Get all test cases from the enum
  let testCases = SVGTestCase.allCases.map(\.rawValue).sorted()

  // Find files without corresponding test cases
  let filesWithoutTestCases = svgFiles.filter { !testCases.contains($0) }

  #expect(
    filesWithoutTestCases.isEmpty,
    "SVG files without test cases: \(filesWithoutTestCases.joined(separator: ", "))"
  )

  // Find test cases without corresponding files
  let testCasesWithoutFiles = testCases.filter { !svgFiles.contains($0) }

  #expect(
    testCasesWithoutFiles.isEmpty,
    "Test cases without SVG files: \(testCasesWithoutFiles.joined(separator: ", "))"
  )
}

// MARK: - Snapshot Testing Utilities

// Check if extended tests (like WebKit reference generation) should run
let extendedTestsEnabled = ProcessInfo.processInfo
  .environment["CGGEN_EXTENDED_TESTS"] == "1"

// Path to the SVGTests.swift file for snapshot testing
let svgTestsFilePath: StaticString = #filePath

extension Snapshotting where Value == CGImage, Format == CGImage {
  static func cgImage(tolerance: Double = 0.002) -> Snapshotting {
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

          let diff = SnapshotTestingSupport.compare(reference, actual)

          if diff < tolerance {
            return nil
          }

          let percentDiff = diff * 100
          let percentTolerance = tolerance * 100
          let message =
            "Difference: \(String(format: "%.3f%%", percentDiff)) (max allowed: \(String(format: "%.1f%%", percentTolerance)))"

          return (message, [])
        }
      )
    ) { $0 }
  }
}
