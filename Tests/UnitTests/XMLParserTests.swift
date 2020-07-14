import XCTest

import Base

class XMLParserTests: XCTestCase {
  func testSimpleXML() throws {
    XCTAssertEqual(try parse(simpleXML), .el("note", children: [
      .el("to", children: [.text("Tove")]),
      .el("from", children: [.text("Jani")]),
      .el("body", children: [.text("Don't forget me this weekend!")]),
    ]))
  }

  func testSimpleSVG() throws {
    XCTAssertEqual(try parse(simpleSVG), .el(
      "svg", attrs: ["width": "50px", "height": "50px"], children: [
        .el("g", attrs: ["stroke": "none", "fill": "none"], children: [
          .el("rect", attrs: ["fill": "#50E3C2", "x": "0", "y": "0"]),
        ]),
      ]
    ))
  }
}

private func parse(_ xml: String) throws -> XML {
  try XML.parse(from: xml.data(using: .utf8).unsafelyUnwrapped).get()
}

private let simpleXML = """
<note>
  <to>Tove</to>
  <from>Jani</from>
  <body>Don't forget me this weekend!</body>
</note>
"""

private let simpleSVG = """
<?xml version="1.0" encoding="UTF-8"?>
<svg width="50px" height="50px">
  <g stroke="none" fill="none">
    <rect fill="#50E3C2" x="0" y="0"></rect>
  </g>
</svg>
"""
