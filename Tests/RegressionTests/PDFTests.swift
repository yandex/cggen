import CoreGraphics
import Foundation
import Testing

import Base

@Suite struct PDFTests {
  @Test func alpha() {
    test(pdf: "alpha")
  }

  @Test func capsJoins() {
    test(pdf: "caps_joins")
  }

  @Test func dashes() {
    test(pdf: "dashes")
  }

  @Test func fill() {
    test(pdf: "fill")
  }

  @Test func gradient() {
    test(pdf: "gradient")
  }

  @Test func gradientRadial() {
    test(pdf: "gradient_radial")
  }

  @Test func gradientShape() {
    test(pdf: "gradient_shape")
  }

  @Test func gradientThreeDots() {
    test(pdf: "gradient_three_dots")
  }

  @Test func gradientWithAlpha() {
    test(pdf: "gradient_with_alpha")
  }

  @Test func gradientWithMask() {
    test(pdf: "gradient_with_mask")
  }

  @Test func groupOpacity() {
    test(pdf: "group_opacity")
  }

  @Test func lines() {
    test(pdf: "lines")
  }

  @Test func nestedTransparentGroup() {
    test(pdf: "nested_transparent_group", tolerance: 0.005)
  }

  @Test func shapes() {
    test(pdf: "shapes", tolerance: 0.005)
  }

  @Test func underlyingObjectWithTinyAlpha() {
    test(pdf: "underlying_object_with_tiny_alpha")
  }

  @Test func whiteCrossScnOperator() {
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
    let path = sample(named: pdf)
    let pdf = CGPDFDocument(path as CFURL)!
    try Base.check(pdf.pages.count == 1, Err("multipage pdf"))
    let reference = try
      pdf.pages[0].render(scale: scale) !! Err("Couldnt create png from \(pdf)")
    try testBC(
      path: path,
      referenceRenderer: { _ in reference },
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
  getCurrentFilePath().appendingPathComponent("pdf_samples")
