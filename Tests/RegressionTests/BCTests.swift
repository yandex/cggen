import CoreGraphics
import Foundation
import XCTest

import BCRunner
import libcggen

private let defTolerance = 0.002
private let defScale = 2.0

let PDFsamplesPath = getCurentFilePath().appendingPathComponent("pdf_samples")

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

func testBC(
  pdf: String,
  tolerance: Double = defTolerance,
  scale: Double = defScale
) {
  let url = PDFsamplesPath.appendingPathComponent(pdf)
    .appendingPathExtension("pdf")
  XCTAssertNoThrow(try testBC(path: url, tolerance: tolerance, scale: scale))
}

func testBC(
  path: URL,
  tolerance: Double = defTolerance,
  scale: Double = defScale
) throws {
  // TODO: Add support for svg

  let reference = try renderPDF(from: path, scale: CGFloat(scale))
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
  context.setAllowsAntialiasing(false)
  try runBytecode(context, fromData: Data(bytecode))
  
  guard let result = context.makeImage() else {
    throw Err("Failed to draw CGImage")
  }
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
