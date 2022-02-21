import XCTest

import Base
import libcggen

class PDFTests: XCTestCase {
  func testAlpha() {
    test(pdf: "alpha")
  }

  func testCapsJoins() {
    test(pdf: "caps_joins")
  }

  func testDashes() {
    test(pdf: "dashes")
  }

  func testFill() {
    test(pdf: "fill")
  }

  func testGradient() {
    test(pdf: "gradient")
  }

  func testGradientRadial() {
    test(pdf: "gradient_radial")
  }

  func testGradientShape() {
    test(pdf: "gradient_shape")
  }

  func testGradientThreeDots() {
    test(pdf: "gradient_three_dots")
  }

  func testGradientWithAlpha() {
    test(pdf: "gradient_with_alpha")
  }

  func testGradientWithMask() {
    test(pdf: "gradient_with_mask")
  }

  func testGroupOpacity() {
    test(pdf: "group_opacity")
  }

  func testLines() {
    test(pdf: "lines")
  }

  func testNestedTransparentGroup() {
    test(pdf: "nested_transparent_group", tolerance: 0.003)
  }

  func testShapes() {
    test(pdf: "shapes", tolerance: 0.005)
  }

  func testUnderlyingObjectWithTinyAlpha() {
    test(pdf: "underlying_object_with_tiny_alpha")
  }

  func testWhiteCrossScnOperator() {
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
  XCTAssertNoThrow(try testBC(
    path: sample(named: pdf),
    referenceRenderer: { try renderPDF(from: $0, scale: scale) },
    scale: scale,
    antialiasing: false,
    tolerance: tolerance
  ))
}

private func sample(named name: String) -> URL {
  samplesPath.appendingPathComponent(name).appendingPathExtension("pdf")
}

private let samplesPath =
  getCurentFilePath().appendingPathComponent("pdf_samples")
