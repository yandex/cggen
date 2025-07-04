import CGGenCore
@preconcurrency import Parsing

enum SVGFilterPrimitiveParser {
  typealias Attribute = SVGAttributeParser
  typealias AttributeGroup = SVGAttributeGroupParser

  private enum Tag: String {
    case feBlend
    case feColorMatrix
    case feComponentTransfer
    case feComposite
    case feConvolveMatrix
    case feDiffuseLighting
    case feDisplacementMap
    case feFlood
    case feGaussianBlur
    case feImage
    case feMerge
    case feMorphology
    case feOffset
    case feSpecularLighting
    case feTile
    case feTurbulence
  }

  struct FilterPrimitiveParser<T: Equatable>: Parser, Sendable {
    typealias Input = XML
    typealias Output = SVG.FilterPrimitiveElement<T>

    let parser: AnyParser<Input, Output>

    init(_ parser: some Parser<Input, Output>) {
      self.parser = parser.eraseToAnyParser()
    }

    var body: AnyParser<Input, Output> {
      parser
    }
  }

  private static func element<Attributes>(
    tag: Tag,
    attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    let tagParser: some Parser<XML.Element, Void> =
      tag.rawValue
        .pullback(\.substring)
        .pullback(\XML.Element.tag)

    return OptionalInput(
      tagParser ~>> (attributes <<~ End())
        .pullback(\.attrs)
    ).pullback(\XML.el)
  }

  private static func elementTagFeBlend<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feBlend, attributes: attributes)
  }

  private static func elementTagFeColorMatrix<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feColorMatrix, attributes: attributes)
  }

  private static func elementTagFeFlood<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feFlood, attributes: attributes)
  }

  private static func elementTagFeGaussianBlur<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feGaussianBlur, attributes: attributes)
  }

  private static func elementTagFeOffset<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feOffset, attributes: attributes)
  }

  static let feBlend = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeBlend.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.FilterPrimitiveIn(.in2)
      Attribute.BlendMode(.mode)
    } |> AttributeGroup.FilterPrimitive.init >>> elementTagFeBlend
  )

  static let feColorMatrix = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeColorMatrix.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.FeColorMatrixType(.type)
      Attribute.NumList(.values)
    } |> AttributeGroup.FilterPrimitive.init >>> elementTagFeColorMatrix
  )

  static let feFlood = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeFlood.init) {
      Attribute.Color(.floodColor)
      Attribute.Num(.floodOpacity)
    } |> AttributeGroup.FilterPrimitive.init >>> elementTagFeFlood
  )

  static let feGaussianBlur = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeGaussianBlur.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.NumberOptionalNumber(.stdDeviation)
    } |> AttributeGroup.FilterPrimitive.init >>> elementTagFeGaussianBlur
  )

  static let feOffset = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeOffset.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.Num(.dx)
      Attribute.Num(.dy)
    } |> AttributeGroup.FilterPrimitive.init >>> elementTagFeOffset
  )
}
