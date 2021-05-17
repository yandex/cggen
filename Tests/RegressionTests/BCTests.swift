import CoreGraphics
import Foundation
import XCTest

import BCRunner
import libcggen

class BCPDFTests: XCTestCase {
  func testAlpha() {
    testBC(pdf: "alpha")
  }

  func testCapsJoins() {
    testBC(pdf: "caps_joins")
  }

  func testDashes() {
    testBC(pdf: "dashes")
  }

  func testFill() {
    testBC(pdf: "fill")
  }

  func testGradient() {
    testBC(pdf: "gradient")
  }

  func testGradientRadial() {
    testBC(pdf: "gradient_radial")
  }

  func testGradientShape() {
    testBC(pdf: "gradient_shape")
  }

  func testGradientThreeDots() {
    testBC(pdf: "gradient_three_dots")
  }

  func testGradientWithAlpha() {
    testBC(pdf: "gradient_with_alpha")
  }

  func testGradientWithMask() {
    testBC(pdf: "gradient_with_mask")
  }

  func testGroupOpacity() {
    testBC(pdf: "group_opacity")
  }

  func testLines() {
    testBC(pdf: "lines")
  }

  func testNestedTransparentGroup() {
    testBC(pdf: "nested_transparent_group", tolerance: 0.003)
  }

  func testShapes() {
    testBC(pdf: "shapes", tolerance: 0.004)
  }

  func testUnderlyingObjectWithTinyAlpha() {
    testBC(pdf: "underlying_object_with_tiny_alpha")
  }

  func testWhiteCrossScnOperator() {
    testBC(pdf: "white_cross_scn_operator")
  }
}

class BCSVGTests: XCTestCase {
  func testSimpliestSVG() {
    testBC(svg: "fill")
  }

  func testLines() {
    testBC(svg: "lines")
  }

  func testAlpha() {
    testBC(svg: "alpha")
  }

  func testGroupOpacity() {
    testBC(svg: "group_opacity")
  }

  func testShapes() {
    testBC(svg: "shapes")
  }

  func testCapsJoins() {
    testBC(svg: "caps_joins")
  }

  func testDashes() {
    testBC(svg: "dashes")
  }

  func testColorNames() {
    testBC(svg: "colornames", size: .init(width: 120, height: 130))
  }

  func testUseTag() {
    testBC(svg: "use_tag")
  }

  func testUseReferencingNotInDefs() {
    testBC(svg: "use_referencing_not_in_defs")
  }

  func testSimpleMask() {
    testBC(svg: "simple_mask")
  }

  func testClipPath() {
    testBC(svg: "clip_path")
  }

  func testTransforms() {
    testBC(svg: "transforms")
  }

  func testMoveToCommands() {
    testBC(svg: "path_move_to_commands")
  }

  func testComplexCurve() {
    testBC(svg: "path_complex_curve")
  }

  func testCircleCommands() {
    testBC(svg: "path_circle_commands")
  }

  func testShortCommands() {
    testBC(svg: "path_short_commands")
  }

  func testRelativeCommands() {
    testBC(svg: "path_relative_commands")
  }

  func testSmoothCurve() {
    testBC(svg: "path_smooth_curve")
  }

  func testFillRule() {
    testBC(svg: "path_fill_rule")
  }

  func testPathFillRuleNonzeroDefault() {
    testBC(svg: "path_fill_rule_nonzero_default")
  }

  func testGradient() {
    testBC(svg: "gradient")
  }

  func testGradientShape() {
    testBC(svg: "gradient_shape")
  }

  func testGradientStroke() {
    testBC(svg: "gradient_stroke")
  }

  func testGradientFillStrokeCombinations() {
    testBC(svg: "gradient_fill_stroke_combinations")
  }

  func testGradientRelative() {
    testBC(svg: "gradient_relative")
  }

  func testGradientWithAlpha() {
    testBC(svg: "gradient_with_alpha")
  }

  func testGradientThreeControlPoints() {
    testBC(svg: "gradient_three_dots")
  }

  func testGradientWithMask() {
    testBC(svg: "gradient_with_mask")
  }

  func testGradientRadial() {
    testBC(svg: "gradient_radial")
  }

  func testGradientUnits() {
    testBC(svg: "gradient_units")
  }

  func testGradientAbsoluteStartEnd() {
    testBC(svg: "gradient_absolute_start_end")
  }

  func testGradientOpacity() {
    testBC(svg: "gradient_opacity")
  }

  func testSimpleShadow() {
    testBC(svg: "simple_shadow", tolerance: 0.019)
  }

  func testDifferentBlurRadiuses() {
    testBC(svg: "different_blur_radius", tolerance: 0.022)
  }
}

class BCCompilationTests: XCTestCase {
  func testCompilation() throws {
    let variousFilenamesDir =
      getCurentFilePath().appendingPathComponent("various_filenames")
    let files = [
      "Capital letter.svg",
      "dash-dash.svg",
      "under_score.svg",
      "white space.svg",
    ]

    let fm = FileManager.default

    let tmpdir = try fm.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: fm.homeDirectoryForCurrentUser,
      create: true
    )
    defer {
      do {
        try fm.removeItem(at: tmpdir)
      } catch {
        fatalError("Unable to clean up dir: \(tmpdir), error: \(error)")
      }
    }

    let header = tmpdir.appendingPathComponent("gen.h").path
    let impl = tmpdir.appendingPathComponent("gen.m")

    try runCggen(
      with: .init(
        objcHeader: header,
        objcPrefix: "Tests",
        objcImpl: nil,
        objcBytecodeImpl: impl.path,
        objcHeaderImportPath: header,
        objcCallerPath: nil,
        callerScale: 1,
        callerAllowAntialiasing: false,
        callerPngOutputPath: nil,
        generationStyle: nil,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { variousFilenamesDir.appendingPathComponent($0).path }
      )
    )

    try clang(
      out: nil,
      files: [impl],
      syntaxOnly: true,
      frameworks: []
    )
  }
}

private let defTolerance = 0.002
private let defScale: CGFloat = 2.0
private let defSize = CGSize(width: 50, height: 50)

let samplesPathPDF = getCurentFilePath().appendingPathComponent("pdf_samples")
let samplesPathSVG = getCurentFilePath().appendingPathComponent("svg_samples")

private func testBC(
  pdf: String,
  tolerance: Double = defTolerance,
  scale: CGFloat = defScale
) {
  let url = samplesPathPDF.appendingPathComponent(pdf)
    .appendingPathExtension("pdf")
  XCTAssertNoThrow(try testBC(
    path: url,
    referenceRenderer: { try renderPDF(from: $0, scale: scale) },
    scale: scale,
    antialiasing: false,
    tolerance: tolerance
  ))
}

private func testBC(
  svg: String,
  tolerance: Double = defTolerance,
  scale: CGFloat = defScale,
  size: CGSize = defSize
) {
  let url = samplesPathSVG.appendingPathComponent(svg)
    .appendingPathExtension("svg")
  XCTAssertNoThrow(try testBC(
    path: url,
    referenceRenderer: {
      try WKWebViewSnapshoter().take(sample: $0, scale: scale, size: size)
        .cgimg()
    },
    scale: scale,
    resultAdjust: { $0.redraw(with: .white) },
    tolerance: tolerance
  ))
}

private func testBC(
  path: URL,
  referenceRenderer: (URL) throws -> CGImage,
  scale: CGFloat,
  antialiasing: Bool = true,
  resultAdjust: (CGImage) -> CGImage = { $0 },
  tolerance: Double
) throws {
  let reference = try referenceRenderer(path)
  let bytecode = try getBytecode(from: path)

  let cs = CGColorSpaceCreateDeviceRGB()
  guard let context = CGContext(
    data: nil,
    width: reference.width,
    height: reference.height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  ) else {
    throw Err("Failed to create CGContext")
  }
  context
    .concatenate(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
  context.setAllowsAntialiasing(antialiasing)
  try runBytecode(context, fromData: Data(bytecode))

  guard let rawResult = context.makeImage() else {
    throw Err("Failed to draw CGImage")
  }
  let result = resultAdjust(rawResult)
  let diff = compare(reference, result)
  XCTAssertLessThan(diff, tolerance)
  if diff >= tolerance {
    XCTContext.runActivity(named: "Diff of \(path.lastPathComponent)") {
      $0.add(.init(image: result, name: "result"))
      $0.add(.init(image: reference, name: "webkitsnapshot"))
      $0.add(.init(image: .diff(lhs: reference, rhs: result), name: "diff"))
    }
  }
}
