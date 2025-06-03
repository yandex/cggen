@preconcurrency import Parsing
import Foundation

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
    @Sendable (Attribute) -> any AttributeParser<T>
  private typealias AttributeParser<T> = NewParser<[String: String], T?>
  private typealias AttributeGroupParser<T> = NewParser<[String: String], T>

  private static func len(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.Length> {
    return attributeParser(SVGAttributeParsers.length, attribute)
  }

  private static func coord(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.Coordinate> {
    return attributeParser(SVGAttributeParsers.length, attribute)
  }

  private static func color(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.Color> {
    return attributeParser(SVGAttributeParsers.rgbcolor, attribute)
  }
  private static func paint(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.Paint> {
    return attributeParser(SVGAttributeParsers.paint, attribute)
  }

  private static func viewBox(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.ViewBox> {
    return attributeParser(SVGAttributeParsers.viewBox, attribute)
  }

  private static func num(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.Float> {
    return attributeParser(SVGAttributeParsers.number, attribute)
  }
  
  private static func numList(
    _ attribute: Attribute
  ) -> some AttributeParser<[SVG.Float]> {
    return attributeParser(SVGAttributeParsers.listOfNumbers, attribute)
  }
  
  private static func numberOptionalNumber(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.NumberOptionalNumber> {
    return attributeParser(SVGAttributeParsers.numberOptionalNumber, attribute)
  }
  
  private static func identifier(
    _ attribute: Attribute
  ) -> some AttributeParser<String> {
    return attributeParser(SVGAttributeParsers.identifier, attribute)
  }
  private static func transform(
    _ attribute: Attribute
  ) -> some AttributeParser<[SVG.Transform]> {
    let parser = attributeParser(SVGAttributeParsers.transformsList, attribute)
    return parser.map { tuple in
      tuple.map { (_, transforms, _) in transforms }
    }
  }
  private static func listOfPoints(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.CoordinatePairs> {
    let parser = attributeParser(SVGAttributeParsers.listOfPoints, attribute)
    return parser.map { tuple in
      tuple.map { (_, points, _) in points }
    }
  }

  private static func pathData(
    _ attribute: Attribute
  ) -> some AttributeParser<[SVG.PathData.Command]> {
    return attributeParser(SVGAttributeParsers.pathData, attribute)
  }
  private static func stopOffset(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.Stop.Offset> {
    return attributeParser(SVGAttributeParsers.stopOffset, attribute)
  }
  private static func fillRule(
    _ attribute: Attribute
  ) -> some AttributeParser<SVG.FillRule> {
    return attributeParser(SVG.FillRule.parser(), attribute)
  }

  private static var version: some AttributeGroupParser<Void> {
    identifier(.version).oldParser.flatMapResult {
      $0.map { $0 == "1.1" ? .success(()) : .failure(Error.invalidVersion($0))
      } ?? .success(())
    }
  }

  private static let lineCap = attributeParser(SVG.LineCap.parser())
  private static let lineJoin = attributeParser(SVG.LineJoin.parser())
  private static let funciri = attributeParser(SVGAttributeParsers.funciri)
  nonisolated(unsafe)
  private static let x: some AttributeParser<SVG.Coordinate>  = coord(.x)
  nonisolated(unsafe)
  private static let y: some AttributeParser<SVG.Coordinate> = coord(.y)
  nonisolated(unsafe)
  private static let width: some AttributeParser<SVG.Length> = len(.width)
  nonisolated(unsafe)
  private static let height: some AttributeParser<SVG.Length> = len(.height)
  private static let colorInterpolation =
    attributeParser(SVG.ColorInterpolation.parser())

  private static var xml: some AttributeGroupParser<Void> {
    zip(identifier(.xmlns), identifier(.xmlnsxlink)) { _, _ in () }
  }

  private static let ignoreAttribute =
    attributeParser(consume(while: always(true)))
  nonisolated(unsafe)
  private static let ignore: some AttributeGroupParser<Void> =
    ignoreAttribute(.maskType).map(always(()))

  private static let dashArray = attributeParser(SVGAttributeParsers.dashArray)

  private static let presentation = zip(
    funciri(.clipPath),
    fillRule(.clipRule),
    funciri(.mask),
    funciri(.filter),
    paint(.fill),
    fillRule(.fillRule),
    num(.fillOpacity),
    paint(.stroke),
    len(.strokeWidth),
    lineCap(.strokeLinecap),
    lineJoin(.strokeLinejoin),
    dashArray(.strokeDasharray),
    len(.strokeDashoffset),
    num(.strokeOpacity),
    num(.opacity),
    color(.stopColor),
    num(.stopOpacity),
    colorInterpolation(.colorInterpolationFilters),
    with: SVG.PresentationAttributes.init
  )

  nonisolated(unsafe)
  private static let core: some AttributeGroupParser<SVG.CoreAttributes> =
    identifier(.id).map(SVG.CoreAttributes.init)

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
    let attrs = try (zip(
      core, presentation,
      width, height, viewBox(.viewBox),
      with: identity
    ) <<~ version <<~ xml <<~ End()).run(el.attrs).get()
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
    _ parser: some AttributeGroupParser<T>
  ) -> some ShapeParser<T> {
    zip(
      core, presentation, transform(.transform), parser,
      with: SVG.ShapeElement<T>.init
    )
  }

  nonisolated(unsafe)
  private static let rect: some ShapeParser<SVG.RectData> = shape(zip(
    x, y, len(.rx), len(.ry),
    width, height,
    with: SVG.RectData.init
  ))
  nonisolated(unsafe)
  private static let polygon: some ShapeParser<SVG.PolygonData> = shape(
    listOfPoints(.points).map(SVG.PolygonData.init)
  )
  nonisolated(unsafe)
  private static let circle: some ShapeParser<SVG.CircleData> = shape(zip(
    coord(.cx), coord(.cy), coord(.r),
    with: SVG.CircleData.init
  ))
  nonisolated(unsafe)
  private static let ellipse: some ShapeParser<SVG.EllipseData> = shape(zip(
    coord(.cx), coord(.cy), len(.rx), len(.ry),
    with: SVG.EllipseData.init
  ))
  nonisolated(unsafe)
  private static let path: some ShapeParser<SVG.PathData> = shape(zip(
    pathData(.d), num(.pathLength), with: SVG.PathData.init
  ))

  public static func rect(from el: XML.Element) throws -> SVG.Rect {
    try (rect <<~ End()).run(el.attrs).get()
  }

  public static func group(from el: XML.Element) throws -> SVG.Group {
    let attrs = try (zip(
      core, presentation, transform(.transform), with: identity
    ) <<~ End()).run(el.attrs).get()
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
        zip(core, presentation, transform(.transform), with: identity) <<~
          End()
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
    try (polygon <<~ End()).run(el.attrs).get()
  }

  public static func circle(from el: XML.Element) throws -> SVG.Circle {
    try (circle <<~ End()).run(el.attrs).get()
  }

  public static func ellipse(from el: XML.Element) throws -> SVG.Ellipse {
    try (ellipse <<~ End()).run(el.attrs).get()
  }

  private static var stop: some AttributeGroupParser<SVG.Stop> {
    zip(core, presentation, stopOffset(.offset), with: SVG.Stop.init)
  }

  public static func stops(from el: XML.Element) throws -> SVG.Stop {
    try (stop <<~ End()).run(el.attrs).get()
  }

  private static let units = attributeParser(SVG.Units.parser())

  public static func linearGradient(
    from el: XML.Element
  ) throws -> SVG.LinearGradient {
    let attrs = try (zip(
      core, presentation, units(.gradientUnits),
      coord(.x1), coord(.y1), coord(.x2), coord(.y2),
      transform(.gradientTransform),
      with: identity
    ) <<~ End()).run(el.attrs).get()
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
    let attrs = try (zip(
      core, presentation, units(.gradientUnits),
      coord(.cx), coord(.cy), len(.r),
      coord(.fx), coord(.fy), transform(.gradientTransform),
      with: identity
    ) <<~ End()).run(el.attrs).get()
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
    try (path <<~ End()).run(el.attrs).get()
  }

  private static let iri: ParserForAttribute<String> =
    attributeParser(SVGAttributeParsers.iri)
  nonisolated(unsafe)
  private static let use: some AttributeGroupParser<SVG.Use> = zip(
    core, presentation,
    transform(.transform),
    x, y, width, height,
    iri(.xlinkHref),
    with: SVG.Use.init
  )
  public static func use(from el: XML.Element) throws -> SVG.Use {
    try (use <<~ End()).run(el.attrs).get()
  }

  public static func mask(from el: XML.Element) throws -> SVG.Mask {
    let attrs = try (zip(
      core, presentation,
      transform(.transform),
      x, y, width, height,
      units(.maskUnits), units(.maskContentUnits),
      with: identity
    ) <<~ ignore <<~ End()).run(el.attrs).get()
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
    let attrs = try (zip(
      core, presentation, transform(.transform), units(.clipPathUnits),
      with: identity
    ) <<~ End()).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      clipPathUnits: attrs.3,
      children: el.children.map(element(from:))
    )
  }

  nonisolated(unsafe) private static
  let filterAttributes: some AttributeGroupParser<SVG.FilterAttributes> = zip(
    core, presentation,
    x, y, width, height, units(.filterUnits),
    with: SVG.FilterAttributes.init
  )

  private static func elementWithChildren<
    Attributes: Equatable, Child: Equatable
  >(
    attributes: some AttributeGroupParser<Attributes>,
    child: some Base.NewParser<XML, Child>
  ) -> some Base.NewParser<XML, SVG.ElementWithChildren<Attributes, Child>> {
    let childParser = Parser<ArraySlice<XML>, Child>.next {
      child.oldParser.run($0)
    }
    let childrenParser: some NewParser<[XML], [Child]> =
      (childParser* <<~ End()).oldParser
        .pullback(\.slice)
    let attrs = (attributes <<~ End())
    return zip(
      attrs.pullback(\XML.Element.attrs),
      childrenParser.pullback(\XML.Element.children),
      with: SVG.ElementWithChildren.init
    ).optional.pullback(\XML.el)
  }

  private static func element<Attributes>(
    tag: Tag,
    attributes: some AttributeGroupParser<Attributes>
  ) -> some NewParser<XML, Attributes> {
    let tag: some NewParser<XML.Element, Void> =
    tag.rawValue.oldParser
      .pullback(\.substring)
      .pullback(\XML.Element.tag)
    
    return (tag ~>> (attributes <<~ End())
      .oldParser.pullback(\.attrs)).oldParser
      .optional.oldParser.pullback(\XML.el)
  }
  
  private static let filterPrimitiveAttributes = zip(
    identifier(.result),
    height, width, x, y,
    with: SVG.FilterPrimitiveCommonAttributes.init
  )

  private static func filterPrimitive<T: Equatable>(
    _ data: some AttributeGroupParser<T>
  ) -> some AttributeGroupParser<SVG.FilterPrimitiveElement<T>> {
    zip(
      core, presentation, filterPrimitiveAttributes, data,
      with: SVG.FilterPrimitiveElement.init
    )
  }

  private static let filterPrimitiveIn =
    attributeParser(SVGAttributeParsers.filterPrimitiveIn)
  private static let blendMode = attributeParser(SVGAttributeParsers.blendMode)
  private static let feColorMatrixType =
    attributeParser(SVG.FilterPrimitiveFeColorMatrix.Kind.parser())

  typealias FilterPrimitiveParser<T: Equatable> = NewParser<
    XML, SVG.FilterPrimitiveElement<T>
  >
  
  private static func elementTagFeBlend<Attributes>(
    _ attributes: some AttributeGroupParser<Attributes>
  ) -> some NewParser<XML, Attributes> {
    element(tag: .feBlend, attributes: attributes)
  }
  
  nonisolated(unsafe)
  private static let feBlend: some FilterPrimitiveParser<
    SVG.FilterPrimitiveFeBlend
  > = zip(
    filterPrimitiveIn(.in),
    filterPrimitiveIn(.in2),
    blendMode(.mode),
    with: SVG.FilterPrimitiveFeBlend.init
  ) |> filterPrimitive >>> elementTagFeBlend

  private static func elementTagFeColorMatrix<Attributes>(
    _ attributes: some AttributeGroupParser<Attributes>
  ) -> some NewParser<XML, Attributes> {
    element(tag: .feColorMatrix, attributes: attributes)
  }
  
  nonisolated(unsafe)
  private static let feColorMatrix: some FilterPrimitiveParser<
    SVG.FilterPrimitiveFeColorMatrix
  > = zip(
    filterPrimitiveIn(.in),
    feColorMatrixType(.type),
    numList(.values),
    with: SVG.FilterPrimitiveFeColorMatrix.init
  ) |> filterPrimitive >>> elementTagFeColorMatrix

  private static func elementTagFeFlood<Attributes>(
    _ attributes: some AttributeGroupParser<Attributes>
  ) -> some NewParser<XML, Attributes> {
    element(tag: .feFlood, attributes: attributes)
  }
  
  nonisolated(unsafe)
  private static let feFlood: some FilterPrimitiveParser<
    SVG.FilterPrimitiveFeFlood
  >  = zip(
    color(.floodColor),
    num(.floodOpacity),
    with: SVG.FilterPrimitiveFeFlood.init
  ) |> filterPrimitive >>> elementTagFeFlood

    private static func elementTagFeGaussianBlur<Attributes>(
      _ attributes: some AttributeGroupParser<Attributes>
    ) -> some NewParser<XML, Attributes> {
      element(tag: .feGaussianBlur, attributes: attributes)
    }

    nonisolated(unsafe)
    private static let feGaussianBlur: some FilterPrimitiveParser<
      SVG.FilterPrimitiveFeGaussianBlur
    >  = zip(
      filterPrimitiveIn(.in),
      numberOptionalNumber(.stdDeviation),
      with: SVG.FilterPrimitiveFeGaussianBlur.init
    ) |> filterPrimitive >>> elementTagFeGaussianBlur

    private static func elementTagFeOffset<Attributes>(
      _ attributes: some AttributeGroupParser<Attributes>
    ) -> some NewParser<XML, Attributes> {
      element(tag: .feOffset, attributes: attributes)
    }

    nonisolated(unsafe)
    private static let feOffset: some FilterPrimitiveParser<
      SVG.FilterPrimitiveFeOffset
    >  = zip(
      filterPrimitiveIn(.in),
      num(.dx),
      num(.dy),
      with: SVG.FilterPrimitiveFeOffset.init
    ) |> filterPrimitive >>> elementTagFeOffset

    private static nonisolated(unsafe)
    let filterPrimitiveContent: some NewParser<
      XML, SVG.FilterPrimitiveContent
    > = OneOf {
      feBlend.map(SVG.FilterPrimitiveContent.feBlend)
      feColorMatrix.map(SVG.FilterPrimitiveContent.feColorMatrix)
      feFlood.map(SVG.FilterPrimitiveContent.feFlood)
      feGaussianBlur.map(SVG.FilterPrimitiveContent.feGaussianBlur)
      feOffset.map(SVG.FilterPrimitiveContent.feOffset)
    }

  nonisolated(unsafe) private static let filter: some NewParser<
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
  _ parser: some SVGAttributeParsers.Parser<T>
) -> @Sendable (Attribute) -> Parser<[String: String], T?> {
  nonisolated(unsafe) let parser = parser
  return {
    key(key: $0.rawValue)~?.oldParser.flatMapResult {
      guard let value = $0 else { return .success(nil) }
      return Result { try parser.map(Optional.some).parse(value) }
    }
  }
}

private func attributeParser<T>(
  _ parser: some SVGAttributeParsers.Parser<T>,
  _ attribute: Attribute
) -> some NewParser<[String: String], T?> {
  nonisolated(unsafe) let parser = parser
  return key(key: attribute.rawValue)~?.oldParser.flatMapResult {
    guard let value = $0 else { return .success(nil) }
    return Result { try parser.map(Optional.some).parse(value) }
  }
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
