import Testing

import CGGenCore

@Suite struct XMLRenderTests {
  @Test func simpleXML() {
    #expect(
      XML.el("note", children: [
        .el("to", children: [.text("Tove")]),
        .el("from", children: [.text("Jani")]),
        .el("body", children: [.text("Hello world!")]),
      ]).render() ==
        "<note><to>Tove</to><from>Jani</from><body>Hello world!</body></note>"
    )
  }

  @Test func xMLWithAttributes() {
    #expect(
      XML.el("rect", attrs: ["size": "10,20"], children: [
        .el("square", attrs: ["size": "5"]),
        .text("Hello"),
      ]).render() ==
        #"<rect size="10,20"><square size="5"></square>Hello</rect>"#
    )
  }
}
