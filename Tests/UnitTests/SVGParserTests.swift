@testable import Base

import XCTest

class SVGParserTests: XCTestCase {
  func testSimpleSVG() throws {
    let dim = SVG.Length(50, .px)
    XCTAssertEqual(try parse(simpleSVG), SVG.Document(
      core: .init(id: nil),
      presentation: .empty,
      width: dim, height: dim, viewBox: nil,
      children: [
        .rect(.init(
          core: .init(id: "test_rect"),
          presentation: .construct {
            $0.fill = .rgb(.init(red: 0x50, green: 0xE3, blue: 0xC2))
          },
          transform: nil,
          data: .init(
            x: 0, y: 0, rx: nil, ry: nil, width: 50, height: 50
          )
        )),
      ]
    ))
  }
}

class SVGAttributesParserTest: XCTestCase {
  func testUtils() {
    let wsp = SVGAttributeParsers.wsp
    let commaWsp = SVGAttributeParsers.commaWsp
    let hexFromSingle = SVGAttributeParsers.hexByteFromSingle
    let rgbcolor = SVGAttributeParsers.rgbcolor
    let paint = SVGAttributeParsers.paint
    let filterIn = SVGAttributeParsers.filterPrimitiveIn
    commaWsp.test(",_", expected: ((), "_"))
    commaWsp.test("  ,_", expected: ((), "_"))
    commaWsp.test(",  _", expected: ((), "_"))
    commaWsp.test(" _", expected: ((), "_"))
    commaWsp.test("_", expected: (nil, "_"))
    wsp.test(" ", expected: ((), ""))
    wsp.test("\n", expected: ((), ""))
    wsp.test("  ", expected: ((), " "))
    hexFromSingle.test("42", expected: (0x44, "2"))
    rgbcolor.test("#08EF", expected: (.init(red: 0x00, green: 0x88, blue: 0xEE), "F"))
    rgbcolor.test("#012 FFF", expected: (.init(red: 0x00, green: 0x11, blue: 0x22), " FFF"))
    rgbcolor.test("#123456F", expected: (.init(red: 0x12, green: 0x34, blue: 0x56), "F"))
    paint.test("none", expected: (.some(.none), ""))
    filterIn.test("BackgroundImageFix", expected: (
      result: SVG.FilterPrimitiveIn.previous("BackgroundImageFix"),
      rest: ""
    ))
    filterIn.test("BackgroundImage", expected: (
      result: SVG.FilterPrimitiveIn.predefined(.backgroundimage),
      rest: ""
    ))
  }

  func testTransform() {
    let p = SVGAttributeParsers.transform
    p.test("translate(12, 13)", expected: (.translate(tx: 12, ty: 13), ""))
  }
}

private func parse(_ xml: String) throws -> SVG.Document {
  try SVGParser.root(from: xml.data(using: .utf8).unsafelyUnwrapped)
}

private let simpleSVG = """
<?xml version="1.0" encoding="UTF-8"?>
<svg width="50px" height="50px">
  <rect fill="#50E3C2" x="0" y="0" width="50" height="50" id="test_rect"></rect>
</svg>
"""
