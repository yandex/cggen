import Base
import Foundation
@preconcurrency import Parsing

enum SVGAttributeGroupParser {
  typealias Attribute = SVGAttributeParser

  // MARK: - Common parsers

  static let x = Attribute.Coord(.x)
  static let y = Attribute.Coord(.y)
  static let width = Attribute.Len(.width)
  static let height = Attribute.Len(.height)

  // MARK: - Group Parsers

  static let version = Attribute.Identifier(.version).compactMap { value in
    if let version = value {
      version == "1.1" ? () : nil
    } else {
      ()
    }
  }

  static let xml = Parse { _, _ in () } with: {
    Attribute.Identifier(.xmlns)
    Attribute.Identifier(.xmlnsxlink)
  }

  static let ignore = Optionally {
    DicitionaryKey<String, String>(SVGParse.Attribute.maskType.rawValue)
  }
  .map { _ in () }

  static let presentation = Parse(SVG.PresentationAttributes.init) {
    Attribute.Funciri(.clipPath)
    Attribute.FillRule(.clipRule)
    Attribute.Funciri(.mask)
    Attribute.Funciri(.filter)
    Attribute.Paint(.fill)
    Attribute.FillRule(.fillRule)
    Attribute.Num(.fillOpacity)
    Attribute.Paint(.stroke)
    Attribute.Len(.strokeWidth)
    Attribute.LineCap(.strokeLinecap)
    Attribute.LineJoin(.strokeLinejoin)
    Attribute.DashArray(.strokeDasharray)
    Attribute.Len(.strokeDashoffset)
    Attribute.Num(.strokeOpacity)
    Attribute.Num(.strokeMiterlimit)
    Attribute.Num(.opacity)
    Attribute.Color(.stopColor)
    Attribute.Num(.stopOpacity)
    Attribute.ColorInterpolation(.colorInterpolationFilters)
  }

  static let core = Attribute.Identifier(.id).map(SVG.CoreAttributes.init)

  static let stop = Parse(SVG.Stop.init) {
    core
    presentation
    Attribute.StopOffset(.offset)
  }

  static let filterPrimitiveAttributes = Parse(SVG
    .FilterPrimitiveCommonAttributes.init
  ) {
    Attribute.Identifier(.result)
    height
    width
    x
    y
  }

  static let filterAttributes = Parse(SVG.FilterAttributes.init) {
    core
    presentation
    x
    y
    width
    height
    Attribute.Units(.filterUnits)
  }

  // MARK: - Filter Primitive Parser

  struct FilterPrimitive<Data: Parser>: Parser
    where Data.Input == [String: String], Data.Output: Equatable {
    let data: Data

    init(_ data: Data) {
      self.data = data
    }

    var body: some Parser<
      [String: String],
      SVG.FilterPrimitiveElement<Data.Output>
    > {
      Parse(SVG.FilterPrimitiveElement<Data.Output>.init) {
        core
        presentation
        filterPrimitiveAttributes
        data
      }
    }
  }

  static func filterPrimitive<Data: Parser>(
    _ data: Data
  ) -> FilterPrimitive<Data>
    where Data.Input == [String: String], Data.Output: Equatable {
    FilterPrimitive(data)
  }
}
