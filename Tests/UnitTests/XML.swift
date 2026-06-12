import Foundation

@preconcurrency import Parsing
@testable import SVGParse

// Test-only XML tree: production code parses SVG directly from the XML
// grammar in SVGParse, so the generic tree exists just to exercise the
// grammar in tests.
enum XML: Equatable {
  struct Element: Equatable {
    var tag: String
    var attrs: [String: String]
    var children: [XML]
  }

  indirect case el(Element)
  case text(String)

  static func el(
    _ tag: String,
    attrs: [String: String] = [:],
    children: [XML] = []
  ) -> XML {
    .el(.init(tag: tag, attrs: attrs, children: children))
  }

  static func parse(
    from data: Data,
    ignoreWhitespaceOnlyLines: Bool = true
  ) -> Result<XML, XMLParseError> {
    guard let text = String(data: data, encoding: .utf8) else {
      return .failure(.implError(
        XMLSwiftParsingError(description: "input is not valid UTF-8")
      ))
    }
    var input = text[...].utf8
    let document = XMLParsing.DocumentParser(
      element: ElementNode(),
      text: TextNode(),
      skipWhitespaceOnlyText: ignoreWhitespaceOnlyLines
    )
    do {
      return try .success(document.parse(&input))
    } catch {
      return .failure(.implError(error))
    }
  }

  func render() -> String {
    switch self {
    case let .el(element):
      let attrs = element.attrs.map { #"\#($0.key)="\#($0.value)""# }
      let children = element.children.map { $0.render() }.joined()
      let openTag = ([element.tag] + attrs).joined(separator: " ")
      return "<\(openTag)>\(children)</\(element.tag)>"
    case let .text(text):
      return text
    }
  }
}

enum XMLParseError: Swift.Error {
  case implError(Error)
}

private struct ElementNode: Parser {
  func parse(_ element: inout XMLParsing.RawElement<XML>) throws -> XML {
    .el(.init(
      tag: element.tag,
      attrs: Dictionary(
        uniqueKeysWithValues: element.attrs.map { ($0.name, String($0.value)) }
      ),
      children: element.children
    ))
  }
}

private struct TextNode: Parser {
  func parse(_ text: inout String) throws -> XML {
    .text(text)
  }
}
