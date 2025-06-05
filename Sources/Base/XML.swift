import CasePaths
import Foundation

@CasePathable
public enum XML: Equatable, Sendable {
  public struct Element: Equatable, Sendable {
    var tag: String
    var attrs: [String: String]
    var children: [XML]
  }

  indirect case el(Element)
  case text(String)

  public static func el(
    _ tag: String,
    attrs: [String: String] = [:],
    children: [XML] = []
  ) -> XML {
    .el(.init(tag: tag, attrs: attrs, children: children))
  }

  public var el: Element? {
    get {
      guard case let .el(el) = self else { return nil }
      return el
    }
    set {
      guard case .el = self, let new = newValue else { return }
      self = .el(new)
    }
  }

  public static func parse(
    from data: Data,
    ignoreWhitespaceOnlyLines: Bool = true
  ) -> Result<XML, XMLParseError> {
    let impl = XMLParser(data: data)
    let delegate = XMLComposer()
    impl.delegate = delegate
    guard impl.parse() else {
      return .failure(.implError(impl.parserError))
    }
    return ignoreWhitespaceOnlyLines ? delegate.xml.flatMap {
      filterOutWhitespaceLines(in: $0) ^^ .emptyXML
    } : delegate.xml
  }

  public func render() -> String {
    switch self {
    case let .el(element):
      // stop-color="#C86DD7"
      let attrs = element.attrs.map { #"\#($0.key)="\#($0.value)""# }
      let children = element.children.map { $0.render() }.joined()
      let openTag = ([element.tag] + attrs).joined(separator: " ")
      return "<\(openTag)>\(children)</\(element.tag)>"
    case let .text(text):
      return text
    }
  }
}

public enum XMLParseError: Swift.Error {
  case elementEndsButDidntStart(name: String)
  case notStarted
  case notEnded
  case unexpectedEOF
  case implError(Error?)
  case emptyXML
}

private class XMLComposer: NSObject, XMLParserDelegate {
  var xml: Result<XML, XMLParseError> = .failure(.notStarted)

  private static let rootTag = "$roottag$"
  private static let rootElement =
    XML.Element(tag: rootTag, attrs: [:], children: [])
  private var elementsStack: [XML.Element] = [rootElement]

  private func stop(_ parser: XMLParser, _ error: XMLParseError) {
    parser.abortParsing()
    xml = .failure(error)
  }

  // MARK: - XMLParserDelegate

  func parserDidStartDocument(_: XMLParser) {
    xml = .failure(.notEnded)
  }

  func parser(
    _: XMLParser,
    didStartElement tag: String,
    namespaceURI _: String?,
    qualifiedName _: String?,
    attributes: [String: String] = [:]
  ) {
    elementsStack.append(
      .init(tag: tag, attrs: attributes, children: [])
    )
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI _: String?,
    qualifiedName _: String?
  ) {
    guard let completeElement = elementsStack.popLast(),
          completeElement.tag == elementName else {
      return stop(parser, .elementEndsButDidntStart(name: elementName))
    }
    elementsStack.modifyLast { $0.children.append(.el(completeElement)) }
  }

  func parser(_: XMLParser, foundCharacters string: String) {
    elementsStack.modifyLast { $0.children.append(.text(string)) }
  }

  func parserDidEndDocument(_ parser: XMLParser) {
    guard let root = elementsStack.popLast(),
          elementsStack.count == 0,
          root.tag == XMLComposer.rootTag,
          root.children.count == 1,
          let rootXML = root.children.first else {
      return stop(parser, .unexpectedEOF)
    }
    xml = .success(rootXML)
  }

  func parser(_: XMLParser, foundComment _: String) {}

  // MARK: Unimplemented

  func parser(
    _: XMLParser, foundIgnorableWhitespace _: String
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundNotationDeclarationWithName _: String,
    publicID _: String?, systemID _: String?
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundUnparsedEntityDeclarationWithName _: String,
    publicID _: String?, systemID _: String?, notationName _: String?
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundAttributeDeclarationWithName _: String,
    forElement _: String, type _: String?, defaultValue _: String?
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundElementDeclarationWithName _: String, model _: String
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundInternalEntityDeclarationWithName _: String,
    value _: String?
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundExternalEntityDeclarationWithName _: String,
    publicID _: String?, systemID _: String?
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, didStartMappingPrefix _: String, toURI _: String
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, didEndMappingPrefix _: String
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundProcessingInstructionWithTarget _: String,
    data _: String?
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, foundCDATA _: Data
  ) {
    fatalError()
  }

  func parser(
    _: XMLParser, resolveExternalEntityName _: String, systemID _: String?
  ) -> Data? {
    fatalError()
  }

  func parser(
    _: XMLParser, parseErrorOccurred error: Error
  ) {
    fatalError("\(error)")
  }

  func parser(
    _: XMLParser, validationErrorOccurred _: Error
  ) {
    fatalError()
  }
}

private func filterOutWhitespaceLines(in xml: XML) -> XML? {
  switch xml {
  case let .el(el):
    return .el(
      el.tag,
      attrs: el.attrs,
      children: el.children.compactMap(filterOutWhitespaceLines)
    )
  case let .text(t):
    return CharacterSet(charactersIn: t).isSubset(of: .whitespacesAndNewlines) ?
      nil : .text(t)
  }
}
