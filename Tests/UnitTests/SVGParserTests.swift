import Base
import XCTest

class SVGParserTests: XCTestCase {
  func testSimpleSVG() throws {
    let dim = SVG.Length(50, .px)
    XCTAssertEqual(try parse(simpleSVG), SVG.Document(width: dim, height: dim, viewBox: nil, children: [
      .rect(SVG.Rect(x: 0, y: 0, width: 50, height: 50, fill: nil, fillOpacity: nil)),
    ]))
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
