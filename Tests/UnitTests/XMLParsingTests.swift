import Foundation
import Testing

import CGGenCore
import SVGParse

@Suite struct XMLParsingTests {
  @Test func simpleXML() throws {
    try #expect(parse("""
    <note>
      <to>Tove</to>
      <from>Jani</from>
      <body>Don't forget me this weekend!</body>
    </note>
    """) == .el("note", children: [
      .el("to", children: [.text("Tove")]),
      .el("from", children: [.text("Jani")]),
      .el("body", children: [.text("Don't forget me this weekend!")]),
    ]))
  }

  @Test func declarationAndAttributes() throws {
    try #expect(parse("""
    <?xml version="1.0" encoding="UTF-8"?>
    <svg width="50px" height="50px">
      <g stroke="none" fill="none">
        <rect fill="#50E3C2" x="0" y="0"></rect>
      </g>
    </svg>
    """) == .el(
      "svg", attrs: ["width": "50px", "height": "50px"], children: [
        .el("g", attrs: ["stroke": "none", "fill": "none"], children: [
          .el("rect", attrs: ["fill": "#50E3C2", "x": "0", "y": "0"]),
        ]),
      ]
    ))
  }

  @Test func entitiesInText() throws {
    try #expect(
      parse("<a>x &amp; y &lt;z&gt; &quot;q&quot; &apos;a&apos;</a>")
        == .el("a", children: [.text("x & y <z> \"q\" 'a'")])
    )
  }

  @Test func entitiesInAttributes() throws {
    try #expect(
      parse(#"<a t="x &amp; &lt;y&gt; &quot;q&quot; &apos;a&apos;"/>"#)
        == .el("a", attrs: ["t": "x & <y> \"q\" 'a'"])
    )
  }

  @Test func numericCharacterReferences() throws {
    try #expect(
      parse("<a>&#65;&#x42;&#x441;</a>")
        == .el("a", children: [.text("ABс")])
    )
  }

  @Test func comments() throws {
    try #expect(parse("""
    <!-- prolog -->
    <a><!-- inside -->text<!-- splits -->run<b/><!-- last --></a>
    <!-- trailing -->
    """) == .el("a", children: [.text("textrun"), .el("b")]))
  }

  @Test func crlfNormalization() throws {
    try #expect(
      parse("<a>line1\r\nline2\rline3</a>")
        == .el("a", children: [.text("line1\nline2\nline3")])
    )
  }

  @Test func attributeWhitespaceNormalization() throws {
    try #expect(
      parse("<a x=\"v\tw\n1\"/>") == .el("a", attrs: ["x": "v w 1"])
    )
  }

  @Test func multilineTextPreserved() throws {
    try #expect(
      parse("<a>line1\nline2\n  line3</a>")
        == .el("a", children: [.text("line1\nline2\n  line3")])
    )
  }

  @Test func nonASCIIText() throws {
    try #expect(
      parse("<a>héllo wörld 日本</a>")
        == .el("a", children: [.text("héllo wörld 日本")])
    )
  }

  @Test func quotingVariants() throws {
    try #expect(
      parse("<a empty=\"\" single='v1'/>")
        == .el("a", attrs: ["empty": "", "single": "v1"])
    )
  }

  @Test func textAroundChildElement() throws {
    try #expect(
      parse("<a>before<b/>after</a>")
        == .el("a", children: [.text("before"), .el("b"), .text("after")])
    )
  }

  @Test func whitespaceOnlyTextFiltered() throws {
    try #expect(
      parse("<a>\n  <b/>\n</a>") == .el("a", children: [.el("b")])
    )
  }

  @Test func whitespaceOnlyTextKeptWhenAskedTo() throws {
    let data = Data("<a>\n  <b/>\n</a>".utf8)
    let xml = try XML.parse(
      from: data, ignoreWhitespaceOnlyLines: false
    ).get()
    #expect(xml == .el("a", children: [
      .text("\n  "), .el("b"), .text("\n"),
    ]))
  }

  @Test(arguments: [
    "<a><b></a>",
    "<a></b></a>",
    "<a>",
    "<a/><b/>",
    "<a>&unknown;</a>",
    "<a>&amp</a>",
    "<a x=\"1\" x=\"2\"/>",
    "<a x=1/>",
    "<a><![CDATA[no]]></a>",
    "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><a/>",
    "",
  ])
  func malformedInputFails(_ xml: String) {
    let result = XML.parse(from: Data(xml.utf8))
    #expect(throws: (any Error).self) { try result.get() }
  }

  @Test(arguments: ["UTF-8", "utf-8", "UTF8"])
  func utf8EncodingDeclarationSpellings(_ name: String) throws {
    let data = Data("<?xml version=\"1.0\" encoding=\"\(name)\"?><a/>".utf8)
    try #expect(XML.parse(from: data).get() == .el("a"))
  }

  @Test func invalidUTF8Fails() {
    let result = XML.parse(from: Data([
      0x3C,
      0x61,
      0x3E,
      0xFF,
      0x3C,
      0x2F,
      0x61,
      0x3E,
    ]))
    #expect(throws: (any Error).self) { try result.get() }
  }
}

private func parse(_ xml: String) throws -> XML {
  try XML.parse(from: Data(xml.utf8)).get()
}
