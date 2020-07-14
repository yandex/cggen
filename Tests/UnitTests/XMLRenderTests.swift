import XCTest

import Base

class XMLRenderTests: XCTestCase {
  func testSimpleXML() {
    XCTAssertEqual(
      XML.el("note", children: [
        .el("to", children: [.text("Tove")]),
        .el("from", children: [.text("Jani")]),
        .el("body", children: [.text("Hello world!")]),
      ]).render(),
      "<note><to>Tove</to><from>Jani</from><body>Hello world!</body></note>"
    )
  }

  func testXMLWithAttributes() {
    XCTAssertEqual(
      XML.el("rect", attrs: ["size": "10,20"], children: [
        .el("square", attrs: ["size": "5"]),
        .text("Hello"),
      ]).render(),
      #"<rect size="10,20"><square size="5"></square>Hello</rect>"#
    )
  }
}
