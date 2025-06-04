import CoreGraphics
import Foundation
import Testing

import Base
import libcggen

@Suite struct PDFTests {
  @Test func testAlpha() {
    test(pdf: "alpha")
  }

  @Test func testCapsJoins() {
    test(pdf: "caps_joins")
  }

  @Test func testDashes() {
    test(pdf: "dashes")
  }

  @Test func testFill() {
    test(pdf: "fill")
  }

  @Test func testGradient() {
    test(pdf: "gradient")
  }

  @Test func testGradientRadial() {
    test(pdf: "gradient_radial")
  }

  @Test func testGradientShape() {
    test(pdf: "gradient_shape")
  }

  @Test func testGradientThreeDots() {
    test(pdf: "gradient_three_dots")
  }

  @Test func testGradientWithAlpha() {
    test(pdf: "gradient_with_alpha")
  }

  @Test func testGradientWithMask() {
    test(pdf: "gradient_with_mask")
  }

  @Test func testGroupOpacity() {
    test(pdf: "group_opacity")
  }

  @Test func testLines() {
    test(pdf: "lines")
  }

  @Test func testNestedTransparentGroup() {
    test(pdf: "nested_transparent_group", tolerance: 0.005)
  }

  @Test func testShapes() {
    test(pdf: "shapes", tolerance: 0.005)
  }

  @Test func testUnderlyingObjectWithTinyAlpha() {
    test(pdf: "underlying_object_with_tiny_alpha")
  }

  @Test func testWhiteCrossScnOperator() {
    test(pdf: "white_cross_scn_operator")
  }
}

private let defaultTolerance = 0.003
private let defaultScale = 2.0

private func test(
  pdf: String,
  tolerance: Double = defaultTolerance,
  scale: CGFloat = defaultScale
) {
  do {
    try testBC(
      path: sample(named: pdf),
      referenceRenderer: { try renderPDF(from: $0, scale: scale) },
      scale: scale,
      antialiasing: false,
      tolerance: tolerance
    )
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
}

private func sample(named name: String) -> URL {
  samplesPath.appendingPathComponent(name).appendingPathExtension("pdf")
}

private let samplesPath =
  getCurentFilePath().appendingPathComponent("pdf_samples")
