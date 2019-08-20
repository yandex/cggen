@testable import Base
import XCTest

class SVGParserTests: XCTestCase {
  func testSimpleSVG() throws {
    let dim = SVG.Length(50, .px)
    XCTAssertEqual(try parse(simpleSVG), SVG.Document(width: dim, height: dim, viewBox: nil, children: [
      .rect(SVG.Rect(
        x: 0, y: 0, width: 50, height: 50,
        presentation: .construct {
          $0.fill = .rgb(.init(red: 0x50, green: 0xE3, blue: 0xC2))
        }
      )),
    ]))
  }
}

class SVGAttributesParserTest: XCTestCase {
  func testUtils() {
    let wsp = SVGAttributesParsers.wsp
    let commaWsp = SVGAttributesParsers.commaWsp
    commaWsp.test(",_", expected: ((), "_"))
    commaWsp.test("  ,_", expected: ((), "_"))
    commaWsp.test(",  _", expected: ((), "_"))
    commaWsp.test(" _", expected: ((), "_"))
    commaWsp.test("_", expected: (nil, "_"))
    wsp.test(" ", expected: ((), ""))
    wsp.test("\n", expected: ((), ""))
    wsp.test("  ", expected: ((), " "))
  }

  func testTransform() {
    let p = SVGAttributesParsers.transform
    p.test("translate(12, 13)", expected: (.translate(tx: 12, ty: 13), ""))
  }
}

private func parse(_ xml: String) throws -> SVG.Document {
  return try SVGParser.root(from: xml.data(using: .utf8).unsafelyUnwrapped)
}

private let simpleSVG = """
<?xml version="1.0" encoding="UTF-8"?>
<svg width="50px" height="50px">
  <rect fill="#50E3C2" x="0" y="0" width="50" height="50"></rect>
</svg>
"""
