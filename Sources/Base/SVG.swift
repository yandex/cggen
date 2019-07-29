import CoreGraphics
import Foundation

public enum SVG: Equatable {
  public typealias Float = Swift.Double

  public struct Length: Equatable {
    public enum Unit: String, CaseIterable {
      case px, pt
      case percent = "%"
    }

    public var number: Float
    public var unit: Unit?
  }

  public typealias Coordinate = SVG.Length

  public struct ViewBox: Equatable {
    public var minx: Float
    public var miny: Float
    public var width: Float
    public var height: Float
  }

  public struct Document: Equatable, ElementWithAttributes {
    public enum Attribute: String, CaseIterable {
      case width, height, viewBox
    }

    public static let tag = "svg"

    public var width: Length?
    public var height: Length?
    public var viewBox: ViewBox?
    public var children: [SVG]

    public var xml: XML {
      return .el("svg", attrs: [
        "width": width?.encode(),
        "height": height?.encode(),
        "viewbox": viewBox?.encode(),
      ].compactMapValues(identity), children: children.map { $0.xml })
    }

    public init(width: Length?, height: Length?, viewBox: ViewBox?, children: [SVG]) {
      self.width = width
      self.height = height
      self.viewBox = viewBox
      self.children = children
    }
  }

  public struct Rect: Equatable, ElementWithAttributes {
    public enum Attribute: String, CaseIterable {
      case x, y, width, height
      case fill, fillOpacity
    }

    public static let tag = "rect"

    var x: Coordinate
    var y: Coordinate
    var width: Coordinate
    var height: Coordinate
    var fill: RGBColor?
    var fillOpacity: Float?

    public init(
      x: SVG.Coordinate,
      y: SVG.Coordinate,
      width: SVG.Coordinate,
      height: SVG.Coordinate,
      fill: RGBColor?,
      fillOpacity: SVG.Float?
    ) {
      self.x = x
      self.y = y
      self.width = width
      self.height = height
      self.fill = fill
      self.fillOpacity = fillOpacity
    }
  }

  public static let insignificantTags: Set<String> = ["title", "desc"]

  indirect case svg(Document)
  case group
  case rect(Rect)
  case polygon
  case mask
  case use
  case defs

  public var xml: XML {
    switch self {
    case let .svg(doc):
      return doc.xml
    case let .rect(r):
      return .el("rect", attrs: [
        "x": "\(r.x)",
        "y": "\(r.y)",
        "width": "\(r.width)",
        "height": "\(r.height)",
        "fill": r.fill?.hexString,
        "fill-opacity": r.fillOpacity?.description,
      ].compactMapValues(identity))
    case .group, .polygon, .mask, .use, .defs:
      fatalError()
    }
  }
}

public protocol SVGAttributeValue {
  func encode() -> String
  static func decode(from string: String) -> Self?
}

public protocol ElementWithAttributes {
  associatedtype Attribute: CaseIterable, RawRepresentable
    where Attribute.RawValue == String

  static var tag: String { get }
}

extension SVG.ViewBox {
  public init(
    _ x: SVG.Float,
    _ y: SVG.Float,
    _ width: SVG.Float,
    _ height: SVG.Float
  ) {
    minx = x
    miny = y
    self.width = width
    self.height = height
  }
}

extension SVG.ViewBox: SVGAttributeValue {
  public static func decode(from string: String) -> Self? {
    let numbers = string.split(separator: " ")
    let parts = numbers.compactMap(SVG.Float.init)
    guard numbers.count == 4, parts.count == 4 else { return nil }
    return .init(parts[0], parts[1], parts[2], parts[3])
  }

  public func encode() -> String {
    return ""
  }
}

extension SVG.Float: SVGAttributeValue {
  public static func decode(from string: String) -> SVG.Float? {
    return SVG.Float(string)
  }

  public func encode() -> String {
    return description
  }
}

extension SVG.Length {
  public init(_ number: SVG.Float, _ unit: Unit? = nil) {
    self.number = number
    self.unit = unit
  }
}

extension SVG.Length: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(.init(value))
  }
}

extension SVG.Length: SVGAttributeValue {
  public func encode() -> String {
    return "\(number)\(unit?.rawValue ?? "")"
  }

  public static func decode(from string: String) -> SVG.Length? {
    let unit = Unit.allCases.first { string.hasSuffix($0.rawValue) }
    let numberString = string.dropLast(unit.map(\.rawValue.count) ?? 0)
    guard let number = SVG.Float(numberString) else {
      return nil
    }
    return .init(number: number, unit: unit)
  }
}

extension RGBColor: SVGAttributeValue {
  public func encode() -> String {
    return hexString
  }

  public static func decode(from string: String) -> RGBColor? {
    guard string.starts(with: "#"),
      let hex = UInt32(string.dropFirst()) else {
      return nil
    }
    return .init(
      red: CGFloat((hex & 0xFF0000) >> 16) / CGFloat(UInt8.max),
      green: CGFloat((hex & 0x00FF00) >> 8) / CGFloat(UInt8.max),
      blue: CGFloat((hex & 0x00FF) >> 0) / CGFloat(UInt8.max)
    )
  }

  var hexString: String {
    let helper: (CGFloat) -> String = {
      String(UInt8($0 * CGFloat(UInt8.max)), radix: 0x10, uppercase: true)
    }
    return [helper(red), helper(green), helper(blue)].joined()
  }
}

public enum SVGParser {
  public enum Error: Swift.Error {
    case expectedSVGTag(got: String)
    case unexpectedXMLText(String)
    case unknownAttributes(tag: String, attributes: Set<String>)
    case invalidAttributeFormat(
      tag: String,
      attribute: String,
      value: String,
      type: String
    )
  }

  private struct Attributes<T: ElementWithAttributes> {
    var attrs: [String: String]

    init(element: XML.Element) {
      precondition(element.tag == T.tag)
      attrs = element.attrs
    }

    static func checked(_ el: XML.Element) throws -> Attributes {
      let attrs = Attributes(element: el)
      try attrs.check()
      return attrs
    }

    subscript<U>(
      _ attribute: T.Attribute
    ) -> Result<U?, Error> where U: SVGAttributeValue {
      attrs[attribute.rawValue].map {
        U.decode(from: $0) ^^ Error.invalidAttributeFormat(
          tag: T.tag,
          attribute: attribute.rawValue,
          value: $0,
          type: "\(U.self)"
        )
      } ?? .success(nil)
    }

    func check() throws {
      let input = Set(attrs.keys)
      let known = T.Attribute.rawValues
      try Base.check(
        input.isSubset(of: known),
        SVGParser.Error.unknownAttributes(
          tag: SVG.Document.tag,
          attributes: input.subtracting(known)
        )
      )
    }
  }

  public static func root(from data: Data) throws -> SVG.Document {
    return try root(from: XML.parse(from: data).get())
  }

  public static func root(from xml: XML) throws -> SVG.Document {
    switch xml {
    case let .el(el):
      try check(el.tag == SVG.Document.tag, Error.expectedSVGTag(got: el.tag))
      return try document(from: el)
    case let .text(t):
      throw Error.unexpectedXMLText(t)
    }
  }

  public static func document(
    from el: XML.Element
  ) throws -> SVG.Document {
    let attr = try Attributes<SVG.Document>.checked(el)
    return try .init(
      width: attr[.width].get(),
      height: attr[.height].get(),
      viewBox: attr[.viewBox].get(),
      children: el.children.map(element(from:))
    )
  }

  public static func rect(from el: XML.Element) throws -> SVG.Rect {
    let attr = try Attributes<SVG.Rect>.checked(el)
    return try .init(
      x: attr[.x].get() ?? 0,
      y: attr[.y].get() ?? 0,
      width: attr[.width].get() ?? 0,
      height: attr[.height].get() ?? 0,
      fill: attr[.fill].get(),
      fillOpacity: attr[.fillOpacity].get()
    )
  }

  public static func element(from xml: XML) throws -> SVG {
    switch xml {
    case let .el(el):
      switch el.tag {
      case SVG.Document.tag:
        return try .svg(document(from: el))
      case SVG.Rect.tag:
        let attrs = Attributes<SVG.Rect>(element: el)
        try attrs.check()
        return try .rect(rect(from: el))
      case let unimplemented:
        fatalError(unimplemented)
      }
    case let .text(t):
      throw Error.unexpectedXMLText(t)
    }
  }
}
