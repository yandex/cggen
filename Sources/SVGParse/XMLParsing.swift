import Foundation

@preconcurrency import Parsing

struct XMLSwiftParsingError: Swift.Error, CustomStringConvertible {
  var description: String
}

typealias XMLInput = Substring.UTF8View

// Parses the XML subset used by SVG: elements with attributes, nesting,
// the XML declaration, comments, text nodes, the predefined entity
// references (`&lt;` `&gt;` `&amp;` `&quot;` `&apos;`) and numeric
// character references. CDATA sections, DTDs and processing instructions
// are not supported.
//
// The structure is parsed from bytes; the meaning of elements and text is
// delegated to sub-parsers over the parsed pieces, so the same grammar can
// build an XML tree or domain types directly.
enum XMLParsing {
  // One element's pieces before interpretation; children already parsed.
  // Attribute values are slices of the document, except when entity
  // references or whitespace normalization forced decoding into a fresh
  // buffer.
  //
  // TODO: apply attributes to the element as they are scanned instead of
  // collecting this array — permutation parsing (Baars/Löh/Swierstra)
  // with branch dispatch by attribute name; the generic combinator could
  // then be extracted and upstreamed to swift-parsing.
  struct RawElement<Node> {
    var tag: String
    var attrs: [(name: String, value: Substring)]
    var children: [Node]
  }

  // 1-based line and byte-column of the first unconsumed byte. Failing
  // parsers leave the input at (or rewound to) the offending construct,
  // so this is the error position.
  static func position(
    ofRemainder remainder: XMLInput, in text: String
  ) -> (line: Int, column: Int) {
    var line = 1
    var column = 1
    for byte in text.utf8[..<remainder.startIndex] {
      if byte == UInt8(ascii: "\n") {
        line += 1
        column = 1
      } else {
        column += 1
      }
    }
    return (line, column)
  }

  // BOM? declaration? misc element misc EOF
  struct DocumentParser<ElementNode: Parser, TextNode: Parser>: Parser
    where ElementNode.Input == RawElement<ElementNode.Output>,
    TextNode.Input == String, TextNode.Output == ElementNode.Output {
    var element: ElementNode
    var text: TextNode
    var skipWhitespaceOnlyText = true

    var body: some Parser<XMLInput, ElementNode.Output> {
      Parse {
        Skip { Optionally { "\u{FEFF}".utf8 } }
        Skip { Optionally { Declaration() } }
        Misc()
        ElementParser(
          element: element,
          text: text,
          skipWhitespaceOnlyText: skipWhitespaceOnlyText
        )
        Misc()
        End()
      }
    }
  }

  // <?xml version="1.0" encoding="UTF-8" standalone="no"?>
  struct Declaration: Parser {
    func parse(_ input: inout XMLInput) throws {
      guard input.starts(with: "<?xml".utf8) else {
        throw XMLSwiftParsingError(description: "expected XML declaration")
      }
      input.removeFirst(5)
      guard skipXMLWhitespace(&input), input.starts(with: "version".utf8)
      else {
        throw XMLSwiftParsingError(
          description: "expected version in XML declaration"
        )
      }
      input.removeFirst(7)
      let version = try quotedLiteral(&input)
      guard version.starts(with: "1.".utf8),
            version.count > 2,
            version.dropFirst(2).allSatisfy(isASCIIDigit)
      else {
        throw XMLSwiftParsingError(description: "unsupported XML version")
      }
      var hadWhitespace = skipXMLWhitespace(&input)
      if input.starts(with: "encoding".utf8) {
        guard hadWhitespace else {
          throw XMLSwiftParsingError(description: "malformed XML declaration")
        }
        input.removeFirst(8)
        let encoding = try quotedLiteral(&input)
        guard let first = encoding.first, isASCIILetter(first),
              encoding.dropFirst().allSatisfy(isEncodingNameByte)
        else {
          throw XMLSwiftParsingError(description: "malformed encoding name")
        }
        // the input is decoded as UTF-8 unconditionally, so a document
        // declaring another encoding must not parse
        guard isUTF8EncodingName(encoding) else {
          throw XMLSwiftParsingError(
            description: "unsupported encoding \(String(decoding: encoding, as: UTF8.self))"
          )
        }
        hadWhitespace = skipXMLWhitespace(&input)
      }
      if input.starts(with: "standalone".utf8) {
        guard hadWhitespace else {
          throw XMLSwiftParsingError(description: "malformed XML declaration")
        }
        input.removeFirst(10)
        let standalone = try quotedLiteral(&input)
        guard standalone.elementsEqual("yes".utf8)
          || standalone.elementsEqual("no".utf8)
        else {
          throw XMLSwiftParsingError(description: "malformed standalone value")
        }
        _ = skipXMLWhitespace(&input)
      }
      guard input.starts(with: "?>".utf8) else {
        throw XMLSwiftParsingError(description: "malformed XML declaration")
      }
      input.removeFirst(2)
    }

    // S? = S? quoted value, raw
    private func quotedLiteral(
      _ input: inout XMLInput
    ) throws -> XMLInput {
      _ = skipXMLWhitespace(&input)
      guard input.first == UInt8(ascii: "=") else {
        throw XMLSwiftParsingError(description: "expected = in XML declaration")
      }
      input.removeFirst()
      _ = skipXMLWhitespace(&input)
      guard let quote = input.first,
            quote == UInt8(ascii: "\"") || quote == UInt8(ascii: "'")
      else {
        throw XMLSwiftParsingError(
          description: "expected quote in XML declaration"
        )
      }
      input.removeFirst()
      let value = input.prefix { $0 != quote }
      input = input[value.endIndex...]
      guard input.first == quote else {
        throw XMLSwiftParsingError(
          description: "unterminated XML declaration value"
        )
      }
      input.removeFirst()
      return value
    }
  }

  // <!-- comment -->; "--" inside is not allowed
  struct Comment: Parser {
    func parse(_ input: inout XMLInput) throws {
      guard input.starts(with: "<!--".utf8) else {
        throw XMLSwiftParsingError(description: "expected comment")
      }
      input.removeFirst(4)
      while true {
        let chunk = input.prefix { !isCommentBreak($0) }
        input = input[chunk.endIndex...]
        guard let byte = input.first else {
          throw XMLSwiftParsingError(description: "unterminated comment")
        }
        switch byte {
        case UInt8(ascii: "-"):
          if input.starts(with: "-->".utf8) {
            input.removeFirst(3)
            return
          }
          guard !input.starts(with: "--".utf8) else {
            throw XMLSwiftParsingError(description: "-- inside comment")
          }
          input.removeFirst()
        case 0xEF:
          try skipCheckingNoncharacter(&input)
        default:
          throw XMLSwiftParsingError(
            description: "illegal character in comment"
          )
        }
      }
    }
  }

  // (comment | whitespace)*
  struct Misc: Parser {
    var body: some Parser<XMLInput, Void> {
      Skip {
        Many {
          OneOf {
            Comment()
            Skip { Prefix(1...) { isXMLWhitespace($0) } }
          }
        }
      }
    }
  }

  struct Name: Parser {
    func parse(_ input: inout XMLInput) throws -> String {
      let name = input.prefix(while: isXMLName)
      guard let first = name.first, isXMLNameStart(first) else {
        throw XMLSwiftParsingError(description: "expected name")
      }
      input = input[name.endIndex...]
      return String(Substring(name))
    }
  }

  // &lt; &gt; &amp; &quot; &apos; &#10; &#x22;
  struct Reference: Parser {
    func parse(_ input: inout XMLInput) throws -> String {
      let rest = input.dropFirst()
      guard input.first == UInt8(ascii: "&"),
            let semicolon = rest.prefix(16).firstIndex(of: UInt8(ascii: ";"))
      else {
        throw XMLSwiftParsingError(description: "malformed entity reference")
      }
      let body = rest[..<semicolon]
      guard let decoded = decodeEntity(body) else {
        throw XMLSwiftParsingError(
          description: "unknown entity &\(String(decoding: body, as: UTF8.self));"
        )
      }
      input = rest[rest.index(after: semicolon)...]
      return decoded
    }
  }

  // One maximal run of character data between markup; empty if none.
  // CRLF and lone CR normalize to LF.
  struct CharData: Parser {
    func parse(_ input: inout XMLInput) throws -> String {
      let first = input.prefix { !isCharDataBreak($0) }
      input = input[first.endIndex...]
      guard let byte = input.first, byte != UInt8(ascii: "<") else {
        return String(Substring(first))
      }
      var out = [UInt8](first)
      while true {
        switch input.first {
        case nil, UInt8(ascii: "<"):
          return String(decoding: out, as: UTF8.self)
        case UInt8(ascii: "&"):
          try out.append(contentsOf: Reference().parse(&input).utf8)
        case UInt8(ascii: "\r"):
          input.removeFirst()
          if input.first == UInt8(ascii: "\n") { input.removeFirst() }
          out.append(UInt8(ascii: "\n"))
        case UInt8(ascii: "]"):
          guard !input.starts(with: "]]>".utf8) else {
            throw XMLSwiftParsingError(description: "]]> in character data")
          }
          input.removeFirst()
          out.append(UInt8(ascii: "]"))
        case 0xEF:
          try skipCheckingNoncharacter(&input)
          out.append(0xEF)
        default:
          throw XMLSwiftParsingError(description: "illegal character in text")
        }
        let chunk = input.prefix { !isCharDataBreak($0) }
        out.append(contentsOf: chunk)
        input = input[chunk.endIndex...]
      }
    }
  }

  // Quoted value; literal tab/LF/CR normalize to space (character
  // references like &#x9; don't), entity references decode. The common
  // entity-free value comes back as a slice of the document.
  struct AttributeValue: Parser {
    func parse(_ input: inout XMLInput) throws -> Substring {
      guard let quote = input.first,
            quote == UInt8(ascii: "\"") || quote == UInt8(ascii: "'")
      else {
        throw XMLSwiftParsingError(
          description: "expected quoted attribute value"
        )
      }
      input.removeFirst()
      let first = input.prefix { $0 != quote && !isAttributeValueBreak($0) }
      input = input[first.endIndex...]
      if input.first == quote {
        input.removeFirst()
        return Substring(first)
      }
      var out = [UInt8](first)
      while true {
        guard let byte = input.first else {
          throw XMLSwiftParsingError(
            description: "unterminated attribute value"
          )
        }
        switch byte {
        case quote:
          input.removeFirst()
          return String(decoding: out, as: UTF8.self)[...]
        case UInt8(ascii: "&"):
          try out.append(contentsOf: Reference().parse(&input).utf8)
        case UInt8(ascii: "<"):
          throw XMLSwiftParsingError(description: "'<' in attribute value")
        case UInt8(ascii: "\r"):
          input.removeFirst()
          if input.first == UInt8(ascii: "\n") { input.removeFirst() }
          out.append(UInt8(ascii: " "))
        case 0x09, 0x0A:
          input.removeFirst()
          out.append(UInt8(ascii: " "))
        case 0xEF:
          try skipCheckingNoncharacter(&input)
          out.append(0xEF)
        default:
          throw XMLSwiftParsingError(
            description: "illegal character in attribute value"
          )
        }
        let chunk = input.prefix { $0 != quote && !isAttributeValueBreak($0) }
        out.append(contentsOf: chunk)
        input = input[chunk.endIndex...]
      }
    }
  }

  // name S? = S? "value"
  struct XMLAttribute: Parser {
    func parse(_ input: inout XMLInput) throws -> (String, Substring) {
      let name = try Name().parse(&input)
      _ = skipXMLWhitespace(&input)
      guard input.first == UInt8(ascii: "=") else {
        throw XMLSwiftParsingError(description: "expected = after \(name)")
      }
      input.removeFirst()
      _ = skipXMLWhitespace(&input)
      return try (name, AttributeValue().parse(&input))
    }
  }

  // < name (S attribute)* S? (/> | > content </ name >)
  struct ElementParser<ElementNode: Parser, TextNode: Parser>: Parser
    where ElementNode.Input == RawElement<ElementNode.Output>,
    TextNode.Input == String, TextNode.Output == ElementNode.Output {
    var element: ElementNode
    var text: TextNode
    var skipWhitespaceOnlyText: Bool

    func parse(_ input: inout XMLInput) throws -> ElementNode.Output {
      let start = input
      guard input.first == UInt8(ascii: "<") else {
        throw XMLSwiftParsingError(description: "expected element start")
      }
      input.removeFirst()
      let tag = try Name().parse(&input)

      var attrs = [(name: String, value: Substring)]()
      while true {
        let hadWhitespace = skipXMLWhitespace(&input)
        guard let byte = input.first else {
          throw XMLSwiftParsingError(
            description: "unexpected end of input in <\(tag)>"
          )
        }
        if byte == UInt8(ascii: "/") {
          input.removeFirst()
          guard input.first == UInt8(ascii: ">") else {
            throw XMLSwiftParsingError(
              description: "expected > after / in <\(tag)>"
            )
          }
          input.removeFirst()
          return try node(
            tag: tag, attrs: attrs, children: [],
            rewinding: &input, to: start
          )
        }
        if byte == UInt8(ascii: ">") {
          input.removeFirst()
          break
        }
        guard hadWhitespace else {
          throw XMLSwiftParsingError(
            description: "expected whitespace before attribute in <\(tag)>"
          )
        }
        let (name, value) = try XMLAttribute().parse(&input)
        guard !attrs.contains(where: { $0.name == name }) else {
          throw XMLSwiftParsingError(
            description: "attribute \(name) redefined in <\(tag)>"
          )
        }
        attrs.append((name, value))
      }

      var children = [ElementNode.Output]()
      var pendingText = ""
      while true {
        let run = try CharData().parse(&input)
        if pendingText.isEmpty {
          pendingText = run
        } else {
          pendingText += run
        }
        guard input.first != nil else {
          throw XMLSwiftParsingError(
            description: "unexpected end of input in <\(tag)>"
          )
        }
        let afterAngle = input.dropFirst().first
        if afterAngle == UInt8(ascii: "!") {
          // a comment inside a text run splits it in two; the node must
          // still be the whole run, so the pending text is kept open
          try Comment().parse(&input)
          continue
        }
        try flushText(&pendingText, into: &children)
        if afterAngle == UInt8(ascii: "/") {
          break
        }
        try children.append(parse(&input))
      }

      input.removeFirst(2) // </
      let closing = try Name().parse(&input)
      guard closing == tag else {
        throw XMLSwiftParsingError(
          description: "</\(closing)> closes <\(tag)>"
        )
      }
      _ = skipXMLWhitespace(&input)
      try ">".utf8.parse(&input)
      return try node(
        tag: tag, attrs: attrs, children: children,
        rewinding: &input, to: start
      )
    }

    // The element sub-parser rejecting means this whole element is the
    // offender, so the input is rewound to its start for the error
    // position to point at the element rather than after it.
    private func node(
      tag: String,
      attrs: [(name: String, value: Substring)],
      children: [ElementNode.Output],
      rewinding input: inout XMLInput,
      to start: XMLInput
    ) throws -> ElementNode.Output {
      var raw = RawElement(tag: tag, attrs: attrs, children: children)
      do {
        return try element.parse(&raw)
      } catch {
        input = start
        throw error
      }
    }

    private func flushText(
      _ pendingText: inout String,
      into children: inout [ElementNode.Output]
    ) throws {
      guard !pendingText.isEmpty else { return }
      defer { pendingText = "" }
      if skipWhitespaceOnlyText, isWhitespaceOnlyText(pendingText) {
        return
      }
      var value = pendingText
      try children.append(text.parse(&value))
    }
  }
}

private func isXMLWhitespace(_ byte: UInt8) -> Bool {
  byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
}

private func isASCIILetter(_ byte: UInt8) -> Bool {
  byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z")
    || byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z")
}

private func isASCIIDigit(_ byte: UInt8) -> Bool {
  byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
}

private func isASCIIHexDigit(_ byte: UInt8) -> Bool {
  isASCIIDigit(byte)
    || byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "f")
    || byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "F")
}

private func isEncodingNameByte(_ byte: UInt8) -> Bool {
  isASCIILetter(byte) || isASCIIDigit(byte)
    || byte == UInt8(ascii: ".") || byte == UInt8(ascii: "_")
    || byte == UInt8(ascii: "-")
}

private func isUTF8EncodingName(_ name: Substring.UTF8View) -> Bool {
  let lowered = name.map { isASCIILetter($0) ? $0 | 0x20 : $0 }
  return lowered.elementsEqual("utf-8".utf8)
    || lowered.elementsEqual("utf8".utf8)
}

private func isXMLNameStart(_ byte: UInt8) -> Bool {
  byte >= 0x80 || isASCIILetter(byte)
    || byte == UInt8(ascii: ":") || byte == UInt8(ascii: "_")
}

private func isXMLName(_ byte: UInt8) -> Bool {
  byte >= 0x80 || isASCIILetter(byte) || isASCIIDigit(byte)
    || byte == UInt8(ascii: ":") || byte == UInt8(ascii: "_")
    || byte == UInt8(ascii: "-") || byte == UInt8(ascii: ".")
}

private func isCharDataBreak(_ byte: UInt8) -> Bool {
  byte == UInt8(ascii: "<") || byte == UInt8(ascii: "&")
    || byte == UInt8(ascii: "]") || byte == 0xEF
    || byte < 0x20 && byte != 0x09 && byte != 0x0A
}

private func isAttributeValueBreak(_ byte: UInt8) -> Bool {
  byte == UInt8(ascii: "&") || byte == UInt8(ascii: "<")
    || byte == 0xEF || byte < 0x20
}

private func isCommentBreak(_ byte: UInt8) -> Bool {
  byte == UInt8(ascii: "-") || byte == 0xEF
    || byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D
}

// U+FFFE and U+FFFF are the only scalars excluded from the XML 1.0 Char
// production representable in valid UTF-8.
private func skipCheckingNoncharacter(_ input: inout XMLInput) throws {
  if input.starts(with: [0xEF, 0xBF, 0xBE]) || input
    .starts(with: [0xEF, 0xBF, 0xBF]) {
    throw XMLSwiftParsingError(description: "noncharacter in document")
  }
  input.removeFirst()
}

private func skipXMLWhitespace(_ input: inout XMLInput) -> Bool {
  let whitespace = input.prefix(while: isXMLWhitespace)
  input = input[whitespace.endIndex...]
  return !whitespace.isEmpty
}

private func isWhitespaceOnlyText(_ text: String) -> Bool {
  CharacterSet(charactersIn: text).isSubset(of: .whitespacesAndNewlines)
}

private let namedEntities: [String: String] = [
  "lt": "<", "gt": ">", "amp": "&", "quot": "\"", "apos": "'",
]

private func decodeEntity(_ body: Substring.UTF8View) -> String? {
  if body.first == UInt8(ascii: "#") {
    let digits = body.dropFirst()
    let scalar: UInt32? = if digits.first == UInt8(ascii: "x"),
                             digits.dropFirst().allSatisfy(isASCIIHexDigit) {
      UInt32(String(decoding: digits.dropFirst(), as: UTF8.self), radix: 16)
    } else if digits.allSatisfy(isASCIIDigit) {
      UInt32(String(decoding: digits, as: UTF8.self))
    } else {
      nil
    }
    return scalar.flatMap(Unicode.Scalar.init).flatMap {
      isLegalXMLScalar($0) ? String(Character($0)) : nil
    }
  }
  return namedEntities[String(decoding: body, as: UTF8.self)]
}

private func isLegalXMLScalar(_ scalar: Unicode.Scalar) -> Bool {
  switch scalar.value {
  case 0x9, 0xA, 0xD, 0x20...0xD7_FF, 0xE0_00...0xFF_FD, 0x1_00_00...0x10_FF_FF:
    true
  default:
    false
  }
}
