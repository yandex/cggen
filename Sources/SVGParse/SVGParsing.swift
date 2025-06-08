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

private enum Attribute: String {
  // XML
  case xmlns, xmlnsxlink = "xmlns:xlink"
  // Core
  case id

  case x, y, width, height, rx, ry

  // Filters
  case result, `in`, in2, mode

  // - Presentation
  case clipRule = "clip-rule", clipPath = "clip-path", mask, opacity
  case filter
  case stopColor = "stop-color", stopOpacity = "stop-opacity"
  case gradientTransform, gradientUnits
  // Color and Painting
  case colorInterpolation = "color-interpolation"
  case colorInterpolationFilters = "color-interpolation-filters"
  case colorProfile = "color-profile"
  case colorRendering = "color-rendering"
  case fill
  case fillOpacity = "fill-opacity", fillRule = "fill-rule"
  case imageRendering = "image-rendering"
  case marker
  case markerEnd = "marker-end", markerMid = "marker-mid"
  case markerStart = "marker-start"
  case shapeRendering = "shape-rendering"
  case stroke
  case strokeDasharray = "stroke-dasharray"
  case strokeDashoffset = "stroke-dashoffset"
  case strokeLinecap = "stroke-linecap", strokeLinejoin = "stroke-linejoin"
  case strokeMiterlimit = "stroke-miterlimit", strokeOpacity = "stroke-opacity"
  case strokeWidth = "stroke-width"
  case textRendering = "text-rendering"

  case viewBox, version
  case points
  case transform
  case offset
  case x1, y1, x2, y2
  case d, pathLength
  case cx, cy, r, fx, fy

  case xlinkHref = "xlink:href"
  case filterUnits
  case type, values, floodColor = "flood-color", floodOpacity = "flood-opacity"
  case stdDeviation
  case dx, dy

  case maskUnits, maskContentUnits, clipPathUnits

  // Ignore
  case maskType = "mask-type"
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
  private enum Error: Swift.Error {
    case expectedSVGTag(got: String)
    case unexpectedXMLText(String)
    case unknown(attribute: String, tag: Tag)
    case nonbelongig(attributes: Set<Attribute>, tag: Tag)
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

  private typealias ParserForAttribute<T> =
    @Sendable (Attribute) -> AttributeParser<T>
  private typealias AttributeParser<T> = AnyParser<[String: String], T?>
  private typealias AttributeGroupParser<T> = AnyParser<[String: String], T>

  private static func len(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.Length> {
    attributeParser(SVGAttributeParsers.length, attribute)
  }

  private static func coord(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.Coordinate> {
    attributeParser(SVGAttributeParsers.length, attribute)
  }

  private static func color(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.Color> {
    attributeParser(SVGAttributeParsers.rgbcolor, attribute)
  }

  private static func paint(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.Paint> {
    attributeParser(SVGAttributeParsers.paint, attribute)
  }

  private static func viewBox(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.ViewBox> {
    attributeParser(SVGAttributeParsers.viewBox, attribute)
  }

  private static func num(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.Float> {
    attributeParser(SVGAttributeParsers.number, attribute)
  }

  private static func numList(
    _ attribute: Attribute
  ) -> AttributeParser<[SVG.Float]> {
    attributeParser(SVGAttributeParsers.listOfNumbers, attribute)
  }

  private static func numberOptionalNumber(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.NumberOptionalNumber> {
    attributeParser(SVGAttributeParsers.numberOptionalNumber, attribute)
  }

  private static func identifier(
    _ attribute: Attribute
  ) -> AttributeParser<String> {
    attributeParser(SVGAttributeParsers.identifier, attribute)
  }

  private static func transform(
    _ attribute: Attribute
  ) -> AttributeParser<[SVG.Transform]> {
    let parser = attributeParser(SVGAttributeParsers.transformsList, attribute)
    return parser.map { tuple in
      tuple.map { _, transforms, _ in transforms }
    }.eraseToAnyParser()
  }

  private static func listOfPoints(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.CoordinatePairs> {
    let parser = attributeParser(SVGAttributeParsers.listOfPoints, attribute)
    return parser.map { tuple in
      tuple.map { _, points, _ in points }
    }.eraseToAnyParser()
  }

  private static func pathData(
    _ attribute: Attribute
  ) -> AttributeParser<[SVG.PathData.Command]> {
    attributeParser(SVGAttributeParsers.pathData, attribute)
  }

  private static func stopOffset(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.Stop.Offset> {
    attributeParser(SVGAttributeParsers.stopOffset, attribute)
  }

  private static func fillRule(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.FillRule> {
    attributeParser(SVG.FillRule.parser(), attribute)
  }

  private static var version: AttributeGroupParser<Void> {
    identifier(.version).compactMap { value in
      if let version = value {
        return version == "1.1" ? () : nil
      } else {
        return ()
      }
    }.eraseToAnyParser()
  }

  private static let lineCap: ParserForAttribute<SVG.LineCap> =
    attributeParser(SVG.LineCap.parser())
  private static let lineJoin: ParserForAttribute<SVG.LineJoin> =
    attributeParser(SVG.LineJoin.parser())
  private static let funciri: ParserForAttribute<String> =
    attributeParser(SVGAttributeParsers.funciri)
  private nonisolated(unsafe)
  static let x: AttributeParser<SVG.Coordinate> = coord(.x)
  private nonisolated(unsafe)
  static let y: AttributeParser<SVG.Coordinate> = coord(.y)
  private nonisolated(unsafe)
  static let width: AttributeParser<SVG.Length> = len(.width)
  private nonisolated(unsafe)
  static let height: AttributeParser<SVG.Length> = len(.height)
  private static let colorInterpolation: ParserForAttribute<
    SVG
      .ColorInterpolation
  > =
    attributeParser(SVG.ColorInterpolation.parser())

  private static var xml: AttributeGroupParser<Void> {
    Parse { _, _ in () } with: {
      identifier(.xmlns)
      identifier(.xmlnsxlink)
    }.eraseToAnyParser()
  }

  private static let ignoreAttribute: ParserForAttribute<Substring> =
    attributeParser(Rest())
  private nonisolated(unsafe)
  static let ignore: AttributeGroupParser<Void> =
    DicitionaryKey<String, String>(Attribute.maskType.rawValue).map { _ in () }
      .eraseToAnyParser()

  private static let dashArray: ParserForAttribute<[SVG.Length]> =
    attributeParser(SVGAttributeParsers.dashArray)

  private static let presentation: AttributeGroupParser<
    SVG
      .PresentationAttributes
  > = Parse(SVG.PresentationAttributes.init) {
    funciri(.clipPath)
    fillRule(.clipRule)
    funciri(.mask)
    funciri(.filter)
    paint(.fill)
    fillRule(.fillRule)
    num(.fillOpacity)
    paint(.stroke)
    len(.strokeWidth)
    lineCap(.strokeLinecap)
    lineJoin(.strokeLinejoin)
    dashArray(.strokeDasharray)
    len(.strokeDashoffset)
    num(.strokeOpacity)
    num(.strokeMiterlimit)
    num(.opacity)
    color(.stopColor)
    num(.stopOpacity)
    colorInterpolation(.colorInterpolationFilters)
  }.eraseToAnyParser()

  private nonisolated(unsafe)
  static let core: AttributeGroupParser<SVG.CoreAttributes> =
    identifier(.id).map(SVG.CoreAttributes.init).eraseToAnyParser()

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
      core
      presentation
      width
      height
      viewBox(.viewBox)
    } <<~ version <<~ xml <<~ End()).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      width: attrs.2,
      height: attrs.3,
      viewBox: attrs.4,
      children: el.children.map(element(from:))
    )
  }

  private typealias ShapeParser<T: Equatable & Sendable> =
    AttributeGroupParser<SVG.ShapeElement<T>>

  private static func shape<T: Equatable & Sendable>(
    _ parser: AttributeGroupParser<T>
  ) -> ShapeParser<T> {
    Parse(SVG.ShapeElement<T>.init) {
      core
      presentation
      transform(.transform)
      parser
    }.eraseToAnyParser()
  }

  private nonisolated(unsafe)
  static let rect: ShapeParser<SVG.RectData> = shape(
    Parse(SVG.RectData.init) {
      x
      y
      len(.rx)
      len(.ry)
      width
      height
    }.eraseToAnyParser()
  )
  private nonisolated(unsafe)
  static let polygon: ShapeParser<SVG.PolygonData> = shape(
    listOfPoints(.points).map(SVG.PolygonData.init).eraseToAnyParser()
  )
  private nonisolated(unsafe)
  static let circle: ShapeParser<SVG.CircleData> = shape(
    Parse(SVG.CircleData.init) {
      coord(.cx)
      coord(.cy)
      coord(.r)
    }.eraseToAnyParser()
  )
  private nonisolated(unsafe)
  static let ellipse: ShapeParser<SVG.EllipseData> = shape(
    Parse(SVG.EllipseData.init) {
      coord(.cx)
      coord(.cy)
      len(.rx)
      len(.ry)
    }.eraseToAnyParser()
  )
  private nonisolated(unsafe)
  static let path: ShapeParser<SVG.PathData> = shape(
    Parse(SVG.PathData.init) {
      pathData(.d)
      num(.pathLength)
    }.eraseToAnyParser()
  )

  public static func rect(from el: XML.Element) throws -> SVG.Rect {
    var attrs = el.attrs
    return try (rect <<~ End()).parse(&attrs)
  }

  public static func group(from el: XML.Element) throws -> SVG.Group {
    let attrs = try (Parse { core, presentation, transform in
      (core, presentation, transform)
    } with: {
      core
      presentation
      transform(.transform)
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
          core
          presentation
          transform(.transform)
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

  private static var stop: AttributeGroupParser<SVG.Stop> {
    Parse(SVG.Stop.init) {
      core
      presentation
      stopOffset(.offset)
    }.eraseToAnyParser()
  }

  public static func stops(from el: XML.Element) throws -> SVG.Stop {
    var attrs = el.attrs
    return try (stop <<~ End()).parse(&attrs)
  }

  private static func units(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.Units> {
    attributeParser(SVG.Units.parser(), attribute)
  }

  public static func linearGradient(
    from el: XML.Element
  ) throws -> SVG.LinearGradient {
    let attrs =
      try (Parse { core, presentation, units, x1, y1, x2, y2, transform in
        (core, presentation, units, x1, y1, x2, y2, transform)
      } with: {
        core
        presentation
        units(.gradientUnits)
        coord(.x1)
        coord(.y1)
        coord(.x2)
        coord(.y2)
        transform(.gradientTransform)
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
        core
        presentation
        units(.gradientUnits)
        coord(.cx)
        coord(.cy)
        len(.r)
        coord(.fx)
        coord(.fy)
        transform(.gradientTransform)
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

  private static let iri: ParserForAttribute<String> =
    attributeParser(SVGAttributeParsers.iri)
  // wip: Remove eraseToAnyParser
  static let use = Parse(SVG.Use.init) {
    core.eraseToAnyParser()
    presentation.eraseToAnyParser()
    transform(.transform).eraseToAnyParser()
    x.eraseToAnyParser()
    y.eraseToAnyParser()
    width.eraseToAnyParser()
    height.eraseToAnyParser()
    iri(.xlinkHref).eraseToAnyParser()
  }

  public static func use(from el: XML.Element) throws -> SVG.Use {
    try (use <<~ End()).run(el.attrs).get()
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
          core
          presentation
          transform(.transform)
          x
          y
          width
          height
          units(.maskUnits)
          units(.maskContentUnits)
        } <<~ ignore <<~ End()
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
      core
      presentation
      transform(.transform)
      units(.clipPathUnits)
    } <<~ End()).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      clipPathUnits: attrs.3,
      children: el.children.map(element(from:))
    )
  }

  private nonisolated(unsafe) static
  let filterAttributes: AttributeGroupParser<SVG.FilterAttributes> = Parse(
    SVG
      .FilterAttributes.init
  ) {
    core
    presentation
    x
    y
    width
    height
    units(.filterUnits)
  }.eraseToAnyParser()

  private static func elementWithChildren<
    Attributes: Equatable, Child: Equatable
  >(
    attributes: AttributeGroupParser<Attributes>,
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
    attributes: AttributeGroupParser<Attributes>
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

  private nonisolated(
    unsafe
  ) static let filterPrimitiveAttributes: AttributeGroupParser<
    SVG
      .FilterPrimitiveCommonAttributes
  > = Parse(
    SVG
      .FilterPrimitiveCommonAttributes.init
  ) {
    identifier(.result)
    height
    width
    x
    y
  }.eraseToAnyParser()

  private static func filterPrimitive<T: Equatable>(
    _ data: AttributeGroupParser<T>
  ) -> AttributeGroupParser<SVG.FilterPrimitiveElement<T>> {
    Parse(SVG.FilterPrimitiveElement<T>.init) {
      core
      presentation
      filterPrimitiveAttributes
      data
    }.eraseToAnyParser()
  }

  private static func filterPrimitiveIn(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.FilterPrimitiveIn> {
    attributeParser(SVGAttributeParsers.filterPrimitiveIn, attribute)
  }

  private static func blendMode(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.BlendMode> {
    attributeParser(SVGAttributeParsers.blendMode, attribute)
  }

  private static func feColorMatrixType(
    _ attribute: Attribute
  ) -> AttributeParser<SVG.FilterPrimitiveFeColorMatrix.Kind> {
    attributeParser(SVG.FilterPrimitiveFeColorMatrix.Kind.parser(), attribute)
  }

  typealias FilterPrimitiveParser<T: Equatable> = Parser<
    XML, SVG.FilterPrimitiveElement<T>
  >

  private static func elementTagFeBlend<Attributes>(
    _ attributes: AttributeGroupParser<Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feBlend, attributes: attributes)
  }

  private nonisolated(unsafe)
  static let feBlend: any FilterPrimitiveParser<
    SVG.FilterPrimitiveFeBlend
  > = Parse(SVG.FilterPrimitiveFeBlend.init) {
    filterPrimitiveIn(.in)
    filterPrimitiveIn(.in2)
    blendMode(.mode)
  }.eraseToAnyParser() |> filterPrimitive >>> elementTagFeBlend

  private static func elementTagFeColorMatrix<Attributes>(
    _ attributes: AttributeGroupParser<Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feColorMatrix, attributes: attributes)
  }

  private nonisolated(unsafe)
  static let feColorMatrix: any FilterPrimitiveParser<
    SVG.FilterPrimitiveFeColorMatrix
  > = Parse(SVG.FilterPrimitiveFeColorMatrix.init) {
    filterPrimitiveIn(.in)
    feColorMatrixType(.type)
    numList(.values)
  }.eraseToAnyParser() |> filterPrimitive >>> elementTagFeColorMatrix

  private static func elementTagFeFlood<Attributes>(
    _ attributes: AttributeGroupParser<Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feFlood, attributes: attributes)
  }

  private nonisolated(unsafe)
  static let feFlood: any FilterPrimitiveParser<
    SVG.FilterPrimitiveFeFlood
  > = Parse(SVG.FilterPrimitiveFeFlood.init) {
    color(.floodColor)
    num(.floodOpacity)
  }.eraseToAnyParser() |> filterPrimitive >>> elementTagFeFlood

  private static func elementTagFeGaussianBlur<Attributes>(
    _ attributes: AttributeGroupParser<Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feGaussianBlur, attributes: attributes)
  }

  private nonisolated(unsafe)
  static let feGaussianBlur: any FilterPrimitiveParser<
    SVG.FilterPrimitiveFeGaussianBlur
  > = Parse(SVG.FilterPrimitiveFeGaussianBlur.init) {
    filterPrimitiveIn(.in)
    numberOptionalNumber(.stdDeviation)
  }.eraseToAnyParser() |> filterPrimitive >>> elementTagFeGaussianBlur

  private static func elementTagFeOffset<Attributes>(
    _ attributes: AttributeGroupParser<Attributes>
  ) -> some Parser<XML, Attributes> {
    element(tag: .feOffset, attributes: attributes)
  }

  private nonisolated(unsafe)
  static let feOffset: any FilterPrimitiveParser<
    SVG.FilterPrimitiveFeOffset
  > = Parse(SVG.FilterPrimitiveFeOffset.init) {
    filterPrimitiveIn(.in)
    num(.dx)
    num(.dy)
  }.eraseToAnyParser() |> filterPrimitive >>> elementTagFeOffset

  private nonisolated(unsafe)
  static let filterPrimitiveContent: some Parser<
    XML, SVG.FilterPrimitiveContent
  > = OneOf {
    AnyParser(feBlend).map(SVG.FilterPrimitiveContent.feBlend)
    AnyParser(feColorMatrix).map(SVG.FilterPrimitiveContent.feColorMatrix)
    AnyParser(feFlood).map(SVG.FilterPrimitiveContent.feFlood)
    AnyParser(feGaussianBlur).map(SVG.FilterPrimitiveContent.feGaussianBlur)
    AnyParser(feOffset).map(SVG.FilterPrimitiveContent.feOffset)
  }

  private nonisolated(unsafe) static let filter: some Parser<
    XML, SVG.Filter
  > = elementWithChildren(
    attributes: filterAttributes, child: filterPrimitiveContent
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

private func attributeParser<T>(
  _ parser: some Parser<Substring, T>
) -> @Sendable (Attribute) -> AnyParser<[String: String], T?> {
  nonisolated(unsafe) let parser = parser
  return { attribute in
    DicitionaryKey<String, String>(attribute.rawValue).map { value -> T? in
      guard let value = value else { return nil }
      return try? parser.parse(value)
    }.eraseToAnyParser()
  }
}

private func attributeParser<T>(
  _ parser: some Parser<Substring, T>,
  _ attribute: Attribute
) -> AnyParser<[String: String], T?> {
  DicitionaryKey(attribute.rawValue).map { value in
    guard let value = value else { return nil }
    return try? parser.parse(value)
  }.eraseToAnyParser()
}

// MARK: - Render

public func renderXML(from document: SVG.Document) -> XML {
  .el("svg", attrs: [
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
      "x": r.data.x?.encode(),
      "y": r.data.y?.encode(),
      "width": r.data.width?.encode(),
      "height": r.data.height?.encode(),
      "fill": r.presentation.fill?.encode(),
      "fill-opacity": r.presentation.fillOpacity?.description,
    ].compactMapValues(identity))
  case .group, .polygon, .mask, .use, .defs, .title, .desc, .linearGradient,
       .circle, .path, .ellipse, .radialGradient, .clipPath, .filter:
    fatalError()
  }
}

extension SVG.Float {
  public func encode() -> String {
    description
  }
}

extension SVG.Length {
  public func encode() -> String {
    "\(number)\(unit?.rawValue ?? "")"
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
    case let .funciri(id):
      return "url(#\(id)"
    }
  }
}

extension SVG.Color {
  var hexString: String {
    hex((red, green, blue))
  }
}

extension SVG.ViewBox {
  public func encode() -> String {
    ""
  }
}

// Helpers

extension SVG.PresentationAttributes {
  public static let empty = SVG.PresentationAttributes(
    clipPath: nil,
    clipRule: nil,
    mask: nil,
    filter: nil,
    fill: nil,
    fillRule: nil,
    fillOpacity: nil,
    stroke: nil,
    strokeWidth: nil,
    strokeLineCap: nil,
    strokeLineJoin: nil,
    strokeDashArray: nil,
    strokeDashOffset: nil,
    strokeOpacity: nil,
    strokeMiterlimit: nil,
    opacity: nil,
    stopColor: nil,
    stopOpacity: nil,
    colorInterpolationFilters: nil
  )

  public static func construct(
    _ constructor: (inout SVG.PresentationAttributes) -> Void
  ) -> SVG.PresentationAttributes {
    var temp = empty
    constructor(&temp)
    return temp
  }
}
