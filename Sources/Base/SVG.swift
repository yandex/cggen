import CoreGraphics
import Foundation

// https://www.w3.org/TR/SVG11/
public enum SVG: Equatable {
  public typealias NotImplemented = Never
  public typealias NotNeeded = Never

  // MARK: Attributes

  public typealias Float = Swift.Double
  public typealias Color = RGBColor<UInt8>

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

  public enum Paint: Equatable {
    case none
    case currentColor(NotNeeded) // Used for animations
    case rgb(Color)
    case funciri(NotImplemented)
  }

  public enum FillRule: String, Equatable {
    case nonzero
    case evenodd
  }

  public enum Transform: Equatable {
    public struct Anchor: Equatable {
      public var cx: Float
      public var cy: Float
    }

    case matrix(NotImplemented)
    case translate(tx: Float, ty: Float?)
    case scale(sx: Float, sy: Float?)
    case rotate(angle: Float, anchor: Anchor?)
    case skewX(NotImplemented)
    case skewY(NotImplemented)
  }

  // MARK: Attribute group

  public struct CoreAttributes: Equatable {
    var id: String?
  }

  public struct PresentationAttributes: Equatable {
    public var fill: Paint?
    public var fillRule: FillRule?
    public var fillOpacity: Float?
    public var stroke: Paint?
    public var strokeWidth: Length?
    public var opacity: SVG.Float?

    public init(
      fill: Paint?,
      fillRule: FillRule?,
      fillOpacity: Float?,
      stroke: Paint?,
      strokeWidth: Length?,
      opacity: Float?
    ) {
      self.fill = fill
      self.fillRule = fillRule
      self.fillOpacity = fillOpacity
      self.stroke = stroke
      self.strokeWidth = strokeWidth
      self.opacity = opacity
    }
  }

  // MARK: Elements

  public struct Document: Equatable {
    public var width: Length?
    public var height: Length?
    public var viewBox: ViewBox?
    public var children: [SVG]

    public init(width: Length?, height: Length?, viewBox: ViewBox?, children: [SVG]) {
      self.width = width
      self.height = height
      self.viewBox = viewBox
      self.children = children
    }
  }

  public struct Rect: Equatable {
    public var x: Coordinate?
    public var y: Coordinate?
    public var width: Coordinate?
    public var height: Coordinate?
    public var presentation: PresentationAttributes

    public init(
      x: SVG.Coordinate?,
      y: SVG.Coordinate?,
      width: SVG.Coordinate?,
      height: SVG.Coordinate?,
      presentation: PresentationAttributes
    ) {
      self.x = x
      self.y = y
      self.width = width
      self.height = height
      self.presentation = presentation
    }
  }

  public struct Group: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var children: [SVG]
  }

  public struct Polygon: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var points: [Float]?
  }

  case svg(Document)
  case group(Group)
  case rect(Rect)
  case polygon(Polygon)
  case mask
  case use
  case defs
  case title(String)
  case desc(String)
}

// MARK: - Serialization

private enum Tag: String {
  case svg, rect, title, desc, g, polygon
}

private enum Attribute: String {
  // XML
  case xmlns, xmlnsxlink = "xmlns:xlink"
  // Core
  case id

  case x, y, width, height

  // Presentation
  case fill, fillRule = "fill-rule", fillOpacity = "fill-opacity"
  case stroke, strokeWidth = "stroke-width"
  case opacity

  case viewBox, version
  case points
  case transform
}

private struct AttributeSet: ExpressibleByArrayLiteral {
  var attributes: Set<Attribute>

  init(arrayLiteral elements: Attribute...) {
    attributes = Set(elements)
    precondition(attributes.count == elements.count)
  }

  private init(attributes: Set<Attribute>) {
    self.attributes = attributes
  }

  static let rect: AttributeSet = [.x, .y, .width, .height]
  static let presentation: AttributeSet = [
    .fill, .fillRule, .fillOpacity,
    .stroke, .strokeWidth, .opacity,
  ]
  static let core: AttributeSet = [.id]

  static func +(lhs: AttributeSet, rhs: AttributeSet) -> AttributeSet {
    precondition(lhs.attributes.intersection(rhs.attributes).isEmpty)
    return .init(attributes: lhs.attributes.union(rhs.attributes))
  }
}

private struct ElementCoding {
  var tag: Tag
  var attributes: AttributeSet

  init(_ tag: Tag, attributes: AttributeSet) {
    self.tag = tag
    self.attributes = attributes
  }

  static let document = ElementCoding(
    .svg, attributes: .rect + [.viewBox, .version, .xmlns, .xmlnsxlink]
  )
  static let rect = ElementCoding(.rect, attributes: .rect + .presentation + .core)
  static let group = ElementCoding(.g, attributes: .presentation + .core + [.transform])
  static let polygon = ElementCoding(.polygon, attributes: .presentation + .core + [.points])
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

// MARK: - Parser

private typealias Decoder<T> = (String) -> T?
private enum Decoders {
  static let paint: Decoder<SVG.Paint> = {
    switch $0 {
    case "none":
      return .some(.none)
    default:
      if $0.starts(with: "#"), let hex = UInt32($0.dropFirst(), radix: 0x10) {
        return withUnsafeBytes(of: hex.littleEndian) {
          .rgb(.init(
            red: $0[2], green: $0[1], blue: $0[0]
          ))
        }
      }
      return nil
    }
  }

  static let length: Decoder<SVG.Length> = { string in
    let unit = SVG.Length.Unit.allCases.first { string.hasSuffix($0.rawValue) }
    let numberString = string.dropLast(unit.map(\.rawValue.count) ?? 0)
    guard let number = SVG.Float(numberString) else {
      return nil
    }
    return .init(number: number, unit: unit)
  }

  static let viewBox: Decoder<SVG.ViewBox> = {
    let numbers = $0.split(separator: " ")
    let parts = numbers.compactMap(SVG.Float.init)
    guard numbers.count == 4, parts.count == 4 else { return nil }
    return .init(parts[0], parts[1], parts[2], parts[3])
  }

  static let float: Decoder<SVG.Float> = {
    SVG.Float($0)
  }

  static func list<T>(
    _ decoder: @escaping Decoder<T>,
    separator: Character = " "
  ) -> Decoder<[T]> {
    return {
      $0.split(separator: separator).map {
        decoder(String($0))
      }.unwrap()
    }
  }
}

public enum SVGParser {
  private enum Error: Swift.Error {
    case expectedSVGTag(got: String)
    case unexpectedXMLText(String)
    case unknown(attribute: String, tag: Tag)
    case nonbelongig(attributes: Set<Attribute>, tag: Tag)
    case invalidAttributeFormat(
      tag: String,
      attribute: String,
      value: String,
      type: String
    )
    case titleHasInvalidFormat(XML)
    case uknownTag(String)
  }

  private struct Attributes {
    private var attrs: [Attribute: String]
    private var info: ElementCoding

    init(element: XML.Element, info: ElementCoding) throws {
      precondition(element.tag == info.tag.rawValue)
      let attrs = element.attrs
      let input = try Dictionary(uniqueKeysWithValues: zip(
        attrs.keys.map { try Attribute(rawValue: $0) !! Error.unknown(attribute: $0, tag: info.tag) },
        attrs.values
      ))
      let known = info.attributes.attributes
      let inputKeys = Set(input.keys)
      try Base.check(
        inputKeys.isSubset(of: known),
        Error.nonbelongig(attributes: inputKeys.subtracting(known), tag: info.tag)
      )
      self.attrs = input
      self.info = info
    }

    func decode<T>(
      _ decoder: @escaping Decoder<T>
    ) -> (Attribute) throws -> T? {
      return { [attrs, info] a in try attrs[a].map {
        try decoder($0) !! Error.invalidAttributeFormat(
          tag: info.tag.rawValue,
          attribute: a.rawValue,
          value: $0,
          type: "\(T.self)"
        )
      } }
    }

    typealias AttributeDecoder<T> = (Attribute) throws -> T?

    var len: AttributeDecoder<SVG.Length> {
      return decode(Decoders.length)
    }

    var coord: AttributeDecoder<SVG.Coordinate> {
      return decode(Decoders.length)
    }

    var paint: AttributeDecoder<SVG.Paint> {
      return decode(Decoders.paint)
    }

    var viewBox: AttributeDecoder<SVG.ViewBox> {
      return decode(Decoders.viewBox)
    }

    var num: AttributeDecoder<SVG.Float> {
      return decode(Decoders.float)
    }

    var id: AttributeDecoder<String> {
      return decode(identity)
    }

    var numList: AttributeDecoder<[SVG.Float]> {
      return decode(Decoders.list(Decoders.float))
    }

    var transform: AttributeDecoder<[SVG.Transform]> {
      return decode { SVGAttributesParsers.transformsList.full($0).value }
    }

    func presentation() throws -> SVG.PresentationAttributes {
      return try .init(
        fill: paint(.fill),
        fillRule: decode(SVG.FillRule.init)(.fillRule),
        fillOpacity: num(.fillOpacity),
        stroke: paint(.stroke),
        strokeWidth: len(.strokeWidth),
        opacity: num(.opacity)
      )
    }

    func core() throws -> SVG.CoreAttributes {
      return try .init(
        id: id(.id)
      )
    }
  }

  public static func root(from data: Data) throws -> SVG.Document {
    return try root(from: XML.parse(from: data).get())
  }

  public static func root(from xml: XML) throws -> SVG.Document {
    switch xml {
    case let .el(el):
      try check(el.tag == Tag.svg.rawValue, Error.expectedSVGTag(got: el.tag))
      return try document(from: el)
    case let .text(t):
      throw Error.unexpectedXMLText(t)
    }
  }

  public static func document(
    from el: XML.Element
  ) throws -> SVG.Document {
    let attr = try Attributes(element: el, info: .document)
    return try .init(
      width: attr.len(.width),
      height: attr.len(.height),
      viewBox: attr.viewBox(.viewBox),
      children: el.children.map(element(from:))
    )
  }

  public static func rect(from el: XML.Element) throws -> SVG.Rect {
    let attr = try Attributes(element: el, info: .rect)
    return try .init(
      x: attr.coord(.x),
      y: attr.coord(.y),
      width: attr.len(.width),
      height: attr.len(.height),
      presentation: attr.presentation()
    )
  }

  public static func group(from el: XML.Element) throws -> SVG.Group {
    let attr = try Attributes(element: el, info: .group)
    return try .init(
      core: attr.core(),
      presentation: attr.presentation(),
      transform: attr.transform(.transform),
      children: el.children.map(element(from:))
    )
  }

  public static func polygon(from el: XML.Element) throws -> SVG.Polygon {
    let attr = try Attributes(element: el, info: .polygon)
    return try .init(
      core: attr.core(),
      presentation: attr.presentation(),
      points: attr.numList(.points)
    )
  }

  public static func element(from xml: XML) throws -> SVG {
    switch xml {
    case let .el(el):
      guard let tag = Tag(rawValue: el.tag) else {
        throw Error.uknownTag(el.tag)
      }
      switch tag {
      case .svg:
        return try .svg(document(from: el))
      case .rect:
        return try .rect(rect(from: el))
      case .title:
        guard el.children.count == 1,
          let child = el.children.first, case let .text(title) = child else {
          throw Error.titleHasInvalidFormat(xml)
        }
        return .title(title)
      case .desc:
        guard el.children.count == 1,
          let child = el.children.first, case let .text(desc) = child else {
          throw Error.titleHasInvalidFormat(xml)
        }
        return .desc(desc)
      case .g:
        return try .group(group(from: el))
      case .polygon:
        return try .polygon(polygon(from: el))
      }
    case let .text(t):
      throw Error.unexpectedXMLText(t)
    }
  }
}

internal enum SVGAttributesParsers {
  typealias Parser<T> = Base.Parser<Substring, T>
  internal static let wsp: Parser<Void> = oneOf([0x20, 0x9, 0xD, 0xA]
    .map(Unicode.Scalar.init).map(Character.init)
    .map(consume)
  )
  internal static let comma: Parser<Void> = ","

  // (wsp+ comma? wsp*) | (comma wsp*)
  internal static let commaWsp: Parser<Void> =
    (wsp+ <<~ comma~? <<~ wsp* | comma ~>> wsp*).map { _ in () }
  internal static let number: Parser<SVG.Float> = double()

  // Has no equivalent in specification, for code deduplication only.
  // "$name" wsp* "(" inBrackets ")"
  internal static func transformTemplate<T>(
    _ name: String,
    _ inBrackets: Parser<T>
  ) -> Parser<T> {
    return (consume(name) ~ " "* ~ "(" ~ wsp*) ~>> inBrackets <<~ (wsp* ~ ")")
  }

  // "translate" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  internal static let translate: Parser<SVG.Transform> =
    transformTemplate("translate", number ~ (commaWsp ~>> number)~?)
    .map { SVG.Transform.translate(tx: $0.0, ty: $0.1) }

  internal static let transformsList: Parser<[SVG.Transform]> = transform*
  internal static let transform: Parser<SVG.Transform> = oneOf([
    translate,
  ])
}

// MARK: - Render

public func renderXML(from document: SVG.Document) -> XML {
  return .el("svg", attrs: [
    "width": document.width?.encode(),
    "height": document.height?.encode(),
    "viewBox": document.viewBox?.encode(),
  ].compactMapValues(identity), children: document.children.map(renderXML))
}

public func renderXML(from svg: SVG) -> XML {
  switch svg {
  case let .svg(doc):
    return renderXML(from: doc)
  case let .rect(r):
    return .el("rect", attrs: [
      "x": r.x?.encode(),
      "y": r.y?.encode(),
      "width": r.width?.encode(),
      "height": r.height?.encode(),
      "fill": r.presentation.fill?.encode(),
      "fill-opacity": r.presentation.fillOpacity?.description,
    ].compactMapValues(identity))
  case .group, .polygon, .mask, .use, .defs, .title, .desc:
    fatalError()
  }
}

extension SVG.Float {
  public func encode() -> String {
    return description
  }
}

extension SVG.Length {
  public func encode() -> String {
    return "\(number)\(unit?.rawValue ?? "")"
  }
}

extension SVG.Paint {
  public func encode() -> String {
    switch self {
    case let .rgb(color):
      return color.hexString
    case .none:
      return "none"
    case .currentColor:
      return "currentColor"
    }
  }
}

extension SVG.Color {
  var hexString: String {
    return hex((red, green, blue))
  }
}

extension SVG.ViewBox {
  public func encode() -> String {
    return ""
  }
}

// Helpers

extension SVG.PresentationAttributes {
  public static func construct(
    _ constructor: (inout SVG.PresentationAttributes) -> Void
  ) -> SVG.PresentationAttributes {
    var temp = SVG.PresentationAttributes(
      fill: nil,
      fillRule: nil,
      fillOpacity: nil,
      stroke: nil,
      strokeWidth: nil,
      opacity: nil
    )
    constructor(&temp)
    return temp
  }
}
