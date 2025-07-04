@testable import CGGenCore
@preconcurrency import Parsing
@testable import SVGParse
import Testing

@Suite struct SVGParserTests {
  @Test func testSimpleSVG() throws {
    let dim = SVG.Length(50, .px)
    #expect(try parse(simpleSVG) == SVG.Document(
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

@Suite struct SVGAttributesParserTest {
  @Test func utils() {
    let wsp = SVGValueParser.wsp
    let commaWsp = SVGValueParser.commaWsp
    let hexFromSingle = SVGValueParser.hexByteFromSingle
    let rgbcolor = SVGValueParser.rgbcolor
    let paint = SVGValueParser.paint
    let filterIn = SVGValueParser.filterPrimitiveIn
    commaWsp.test(",_", expected: ((), "_"))
    commaWsp.test("  ,_", expected: ((), "_"))
    commaWsp.test(",  _", expected: ((), "_"))
    commaWsp.test(" _", expected: ((), "_"))
    commaWsp.test("_", expected: (nil, "_"))
    wsp.test(" ", expected: ((), ""))
    wsp.test("\n", expected: ((), ""))
    wsp.test("  ", expected: ((), " "))
    hexFromSingle.test("42", expected: (0x44, "2"))
    rgbcolor.test(
      "#08EF",
      expected: (.init(red: 0x00, green: 0x88, blue: 0xEE), "F")
    )
    rgbcolor.test(
      "#012 FFF",
      expected: (.init(red: 0x00, green: 0x11, blue: 0x22), " FFF")
    )
    rgbcolor.test(
      "#123456F",
      expected: (.init(red: 0x12, green: 0x34, blue: 0x56), "F")
    )
    paint.test("none", expected: (SVG.Paint.none, ""))
    filterIn.test("BackgroundImageFix", expected: (
      result: SVG.FilterPrimitiveIn.previous("BackgroundImageFix"),
      rest: ""
    ))
    filterIn.test("BackgroundImage", expected: (
      result: SVG.FilterPrimitiveIn.predefined(.backgroundimage),
      rest: ""
    ))
  }

  @Test func testTransform() {
    let p = SVGValueParser.transform
    p.test(
      "translate(12, 13)",
      expected: (SVG.Transform.translate(tx: 12, ty: 13), "")
    )
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

extension Parser where Input == Substring, Output: Equatable {
  func test(
    _ data: String,
    expected: (result: Output?, rest: String)
  ) {
    var dataToParse = Substring(data)
    let res = Result { try parse(&dataToParse) }
    #expect(expected.result == res.value)
    #expect(expected.rest == String(dataToParse))
  }
}

extension Parser where Input == Substring, Output == Void {
  func test(
    _ data: String,
    expected: (result: Void?, rest: String) = ((), "")
  ) {
    var data = Substring(data)
    let result: Void? = try? parse(&data)
    if expected.result == nil {
      #expect(result == nil)
    } else {
      #expect(result != nil)
    }
    #expect(String(data) == expected.rest)
  }
}

// Helpers for tests

extension SVG.PresentationAttributes {
  static let empty = SVG.PresentationAttributes(
    clipPath: nil,
    clipRule: nil,
    mask: nil,
    filter: nil,
    fill: nil,
    fillRule: nil,
    fillOpacity: nil,
    stroke: nil,
    strokeWidth: nil,
    strokeLineCap: nil,
    strokeLineJoin: nil,
    strokeDashArray: nil,
    strokeDashOffset: nil,
    strokeOpacity: nil,
    strokeMiterlimit: nil,
    opacity: nil,
    stopColor: nil,
    stopOpacity: nil,
    colorInterpolationFilters: nil
  )

  static func construct(
    _ constructor: (inout SVG.PresentationAttributes) -> Void
  ) -> SVG.PresentationAttributes {
    var temp = empty
    constructor(&temp)
    return temp
  }
}
