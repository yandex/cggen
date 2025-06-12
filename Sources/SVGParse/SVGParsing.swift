import Foundation

import Base
@preconcurrency import Parsing

private enum Tag: String {
  // shape
  case circle, ellipse, polygon, rect, path
  // structural
  case defs, g, svg, use
  // gradient
  case linearGradient, radialGradient
  // descriptive
  case title, desc

  case stop, mask, clipPath, filter

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

public enum SVGParser {
  typealias Attribute = SVGAttributeParser
  typealias AttributeGroup = SVGAttributeGroupParser

  private enum Error: Swift.Error {
    case expectedSVGTag(got: String)
    case unexpectedXMLText(String)
    case unknown(attribute: String, tag: Tag)
    case nonbelongig(attributes: Set<SVGParse.Attribute>, tag: Tag)
    case invalidAttributeFormat(
      tag: String,
      attribute: String,
      value: String,
      type: String,
      parseError: Swift.Error
    )
    case titleHasInvalidFormat(XML)
    case uknownTag(String)
    case invalidVersion(String)
    case notImplemented
  }

  public static func root(from data: Data) throws -> SVG.Document {
    try root(from: XML.parse(from: data).get())
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
    let attrs = try (Parse { core, presentation, width, height, viewBox in
      (core, presentation, width, height, viewBox)
    } with: {
      AttributeGroup.core
      AttributeGroup.presentation
      AttributeGroup.width
      AttributeGroup.height
      Attribute.ViewBox(.viewBox)
    } <<~ AttributeGroup.version <<~ AttributeGroup.xml <<~ End()).run(el.attrs)
      .get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      width: attrs.2,
      height: attrs.3,
      viewBox: attrs.4,
      children: el.children.map(element(from:))
    )
  }

  private struct ShapeParser<T: Equatable & Sendable>: Parser {
    typealias Input = [String: String]
    typealias Output = SVG.ShapeElement<T>

    let parser: AnyParser<Input, Output>

    init(_ parser: some Parser<Input, Output>) {
      self.parser = parser.eraseToAnyParser()
    }

    var body: AnyParser<Input, Output> {
      parser
    }
  }

  private static func shape<T: Equatable & Sendable>(
    _ parser: some Parser<[String: String], T>
  ) -> ShapeParser<T> {
    ShapeParser(
      Parse(SVG.ShapeElement<T>.init) {
        AttributeGroup.core
        AttributeGroup.presentation
        Attribute.Transform(.transform)
        parser
      }
    )
  }

  private static let rect: ShapeParser<SVG.RectData> = shape(
    Parse(SVG.RectData.init) {
      AttributeGroup.x
      AttributeGroup.y
      Attribute.Len(.rx)
      Attribute.Len(.ry)
      AttributeGroup.width
      AttributeGroup.height
    }
  )
  private static let polygon: ShapeParser<SVG.PolygonData> = shape(
    Attribute.ListOfPoints(.points).map(SVG.PolygonData.init)
  )
  private static let circle: ShapeParser<SVG.CircleData> = shape(
    Parse(SVG.CircleData.init) {
      Attribute.Coord(.cx)
      Attribute.Coord(.cy)
      Attribute.Coord(.r)
    }
  )
  private static let ellipse: ShapeParser<SVG.EllipseData> = shape(
    Parse(SVG.EllipseData.init) {
      Attribute.Coord(.cx)
      Attribute.Coord(.cy)
      Attribute.Len(.rx)
      Attribute.Len(.ry)
    }
  )
  private static let path: ShapeParser<SVG.PathData> = shape(
    Parse(SVG.PathData.init) {
      Attribute.PathData(.d)
      Attribute.Num(.pathLength)
    }
  )

  public static func rect(from el: XML.Element) throws -> SVG.Rect {
    var attrs = el.attrs
    return try (rect <<~ End()).parse(&attrs)
  }

  public static func group(from el: XML.Element) throws -> SVG.Group {
    let attrs = try (Parse { core, presentation, transform in
      (core, presentation, transform)
    } with: {
      AttributeGroup.core
      AttributeGroup.presentation
      Attribute.Transform(.transform)
    } <<~ End()).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      children: el.children.map(element(from:))
    )
  }

  public static func defs(from el: XML.Element) throws -> SVG.Defs {
    let attrs =
      try (
        Parse { core, presentation, transform in
          (core, presentation, transform)
        } with: {
          AttributeGroup.core
          AttributeGroup.presentation
          Attribute.Transform(.transform)
        } <<~ End()
      )
      .run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      children: el.children.map(element(from:))
    )
  }

  public static func polygon(from el: XML.Element) throws -> SVG.Polygon {
    var attrs = el.attrs
    return try (polygon <<~ End()).parse(&attrs)
  }

  public static func circle(from el: XML.Element) throws -> SVG.Circle {
    var attrs = el.attrs
    return try (circle <<~ End()).parse(&attrs)
  }

  public static func ellipse(from el: XML.Element) throws -> SVG.Ellipse {
    var attrs = el.attrs
    return try (ellipse <<~ End()).parse(&attrs)
  }

  public static func stops(from el: XML.Element) throws -> SVG.Stop {
    var attrs = el.attrs
    return try (AttributeGroup.stop <<~ End()).parse(&attrs)
  }

  public static func linearGradient(
    from el: XML.Element
  ) throws -> SVG.LinearGradient {
    let attrs =
      try (Parse { core, presentation, units, x1, y1, x2, y2, transform in
        (core, presentation, units, x1, y1, x2, y2, transform)
      } with: {
        AttributeGroup.core
        AttributeGroup.presentation
        Attribute.Units(.gradientUnits)
        Attribute.Coord(.x1)
        Attribute.Coord(.y1)
        Attribute.Coord(.x2)
        Attribute.Coord(.y2)
        Attribute.Transform(.gradientTransform)
      } <<~ End()).run(el.attrs).get()
    let subelements: [XML.Element] = try el.children.map {
      switch $0 {
      case let .el(el):
        return el
      case let .text(t):
        throw Error.unexpectedXMLText(t)
      }
    }
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      unit: attrs.2,
      x1: attrs.3,
      y1: attrs.4,
      x2: attrs.5,
      y2: attrs.6,
      gradientTransform: attrs.7,
      stops: subelements.map(stops(from:))
    )
  }

  public static func radialGradient(
    from el: XML.Element
  ) throws -> SVG.RadialGradient {
    let attrs =
      try (Parse { core, presentation, units, cx, cy, r, fx, fy, transform in
        (core, presentation, units, cx, cy, r, fx, fy, transform)
      } with: {
        AttributeGroup.core
        AttributeGroup.presentation
        Attribute.Units(.gradientUnits)
        Attribute.Coord(.cx)
        Attribute.Coord(.cy)
        Attribute.Len(.r)
        Attribute.Coord(.fx)
        Attribute.Coord(.fy)
        Attribute.Transform(.gradientTransform)
      } <<~ End()).run(el.attrs).get()
    let subelements: [XML.Element] = try el.children.map {
      switch $0 {
      case let .el(el):
        return el
      case let .text(t):
        throw Error.unexpectedXMLText(t)
      }
    }
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      unit: attrs.2,
      cx: attrs.3,
      cy: attrs.4,
      r: attrs.5,
      fx: attrs.6,
      fy: attrs.7,
      gradientTransform: attrs.8,
      stops: subelements.map(stops(from:))
    )
  }

  public static func path(from el: XML.Element) throws -> SVG.Path {
    var attrs = el.attrs
    return try (path <<~ End()).parse(&attrs)
  }

  // wip: Remove eraseToAnyParser
  fileprivate static let useParser = Parse(SVG.Use.init) {
    AttributeGroup.core
    AttributeGroup.presentation
    Attribute.Transform(.transform)
    AttributeGroup.x
    AttributeGroup.y
    AttributeGroup.width
    AttributeGroup.height
    Attribute.Iri(.xlinkHref)
  }

  public static func use(from el: XML.Element) throws -> SVG.Use {
    try (useParser <<~ End()).run(el.attrs).get()
  }

  public static func mask(from el: XML.Element) throws -> SVG.Mask {
    let attrs =
      try (
        Parse { core, presentation, transform, x, y, width, height, maskUnits, maskContentUnits in
          (
            core,
            presentation,
            transform,
            x,
            y,
            width,
            height,
            maskUnits,
            maskContentUnits
          )
        } with: {
          AttributeGroup.core
          AttributeGroup.presentation
          Attribute.Transform(.transform)
          AttributeGroup.x
          AttributeGroup.y
          AttributeGroup.width
          AttributeGroup.height
          Attribute.Units(.maskUnits)
          Attribute.Units(.maskContentUnits)
        } <<~ AttributeGroup.ignore <<~ End()
      ).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      x: attrs.3,
      y: attrs.4,
      width: attrs.5,
      height: attrs.6,
      maskUnits: attrs.7,
      maskContentUnits: attrs.8,
      children: el.children.map(element(from:))
    )
  }

  public static func clipPath(from el: XML.Element) throws -> SVG.ClipPath {
    let attrs = try (Parse { core, presentation, transform, units in
      (core, presentation, transform, units)
    } with: {
      AttributeGroup.core
      AttributeGroup.presentation
      Attribute.Transform(.transform)
      Attribute.Units(.clipPathUnits)
    } <<~ End()).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      clipPathUnits: attrs.3,
      children: el.children.map(element(from:))
    )
  }

  private static func elementWithChildren<
    Attributes: Equatable, Child: Equatable
  >(
    attributes: some Parser<[String: String], Attributes>,
    child: some Parser<XML, Child>
  ) -> some Parser<XML, SVG.ElementWithChildren<Attributes, Child>> {
    let childParser = First<ArraySlice<XML>>().compactMap { element in
      try? child.parse(element)
    }
    let childrenParser: some Parser<[XML], [Child]> =
      (childParser* <<~ End())
        .pullback(\.slice)
    let attrs = (attributes <<~ End())
    return OptionalInput(Parse(SVG.ElementWithChildren.init) {
      attrs.pullback(\XML.Element.attrs)
      childrenParser.pullback(\XML.Element.children)
    }).pullback(\XML.el)
  }

  private static func element<Attributes>(
    tag: Tag,
    attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    let tag: some Parser<XML.Element, Void> =
      tag.rawValue
        .pullback(\.substring)
        .pullback(\XML.Element.tag)

    return OptionalInput(
      tag ~>> (attributes <<~ End())
        .pullback(\.attrs)
    ).pullback(\XML.el)
  }

  struct FilterPrimitiveParser<T: Equatable>: Parser {
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

  private static func elementTagFeBlend<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feBlend, attributes: attributes)
  }

  private static let feBlend: FilterPrimitiveParser<
    SVG.FilterPrimitiveFeBlend
  > = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeBlend.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.FilterPrimitiveIn(.in2)
      Attribute.BlendMode(.mode)
    } |> AttributeGroup.filterPrimitive >>> elementTagFeBlend
  )

  private static func elementTagFeColorMatrix<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feColorMatrix, attributes: attributes)
  }

  private static let feColorMatrix: FilterPrimitiveParser<
    SVG.FilterPrimitiveFeColorMatrix
  > = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeColorMatrix.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.FeColorMatrixType(.type)
      Attribute.NumList(.values)
    } |> AttributeGroup
      .filterPrimitive >>> elementTagFeColorMatrix
  )

  private static func elementTagFeFlood<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feFlood, attributes: attributes)
  }

  private static let feFlood: FilterPrimitiveParser<
    SVG.FilterPrimitiveFeFlood
  > = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeFlood.init) {
      Attribute.Color(.floodColor)
      Attribute.Num(.floodOpacity)
    } |> AttributeGroup.filterPrimitive >>> elementTagFeFlood
  )

  private static func elementTagFeGaussianBlur<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feGaussianBlur, attributes: attributes)
  }

  private static let feGaussianBlur: FilterPrimitiveParser<
    SVG.FilterPrimitiveFeGaussianBlur
  > = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeGaussianBlur.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.NumberOptionalNumber(.stdDeviation)
    } |> AttributeGroup
      .filterPrimitive >>> elementTagFeGaussianBlur
  )

  private static func elementTagFeOffset<Attributes>(
    _ attributes: some Parser<[String: String], Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feOffset, attributes: attributes)
  }

  private static let feOffset: FilterPrimitiveParser<
    SVG.FilterPrimitiveFeOffset
  > = FilterPrimitiveParser(
    Parse(SVG.FilterPrimitiveFeOffset.init) {
      Attribute.FilterPrimitiveIn(.in)
      Attribute.Num(.dx)
      Attribute.Num(.dy)
    } |> AttributeGroup
      .filterPrimitive >>> elementTagFeOffset
  )

  private nonisolated(unsafe)
  static let filterPrimitiveContent: some Parser<
    XML, SVG.FilterPrimitiveContent
  > = OneOf {
    feBlend.map(SVG.FilterPrimitiveContent.feBlend)
    feColorMatrix.map(SVG.FilterPrimitiveContent.feColorMatrix)
    feFlood.map(SVG.FilterPrimitiveContent.feFlood)
    feGaussianBlur.map(SVG.FilterPrimitiveContent.feGaussianBlur)
    feOffset.map(SVG.FilterPrimitiveContent.feOffset)
  }

  private nonisolated(unsafe) static let filter: some Parser<
    XML, SVG.Filter
  > = elementWithChildren(
    attributes: AttributeGroup.filterAttributes, child: filterPrimitiveContent
  )

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
        guard case let .text(title)? = el.children.firstAndOnly else {
          throw Error.titleHasInvalidFormat(xml)
        }
        return .title(title)
      case .desc:
        guard case let .text(desc)? = el.children.firstAndOnly else {
          throw Error.titleHasInvalidFormat(xml)
        }
        return .desc(desc)
      case .g:
        return try .group(group(from: el))
      case .polygon:
        return try .polygon(polygon(from: el))
      case .defs:
        return try .defs(defs(from: el))
      case .linearGradient:
        return try .linearGradient(linearGradient(from: el))
      case .radialGradient:
        return try .radialGradient(radialGradient(from: el))
      case .stop:
        fatalError()
      case .path:
        return try .path(path(from: el))
      case .circle:
        return try .circle(circle(from: el))
      case .ellipse:
        return try .ellipse(ellipse(from: el))
      case .mask:
        return try .mask(mask(from: el))
      case .use:
        return try .use(use(from: el))
      case .clipPath:
        return try .clipPath(clipPath(from: el))
      case .filter:
        return try .filter(filter.run(xml).get())
      case .feColorMatrix,
           .feComponentTransfer,
           .feComposite,
           .feConvolveMatrix,
           .feDiffuseLighting,
           .feDisplacementMap,
           .feBlend,
           .feFlood,
           .feGaussianBlur,
           .feImage,
           .feMerge,
           .feMorphology,
           .feOffset,
           .feSpecularLighting,
           .feTile,
           .feTurbulence:
        fatalError()
      }
    case let .text(t):
      throw Error.unexpectedXMLText(t)
    }
  }
}
