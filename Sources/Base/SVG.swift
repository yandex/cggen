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

  // Should be tuple, when Equatable synthesys improves
  // https://bugs.swift.org/browse/SR-1222
  public struct CoordinatePair: Equatable {
    public var _1: Float
    public var _2: Float
    public init(_ pair: (Float, Float)) {
      _1 = pair.0
      _2 = pair.1
    }
  }

  // Should be tuple, when Equatable synthesys improves
  // https://bugs.swift.org/browse/SR-1222
  public struct NumberOptionalNumber: Equatable {
    public var _1: Float
    public var _2: Float?
  }

  public typealias CoordinatePairs = [CoordinatePair]

  public struct ViewBox: Equatable {
    public var minx: Float
    public var miny: Float
    public var width: Float
    public var height: Float

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

  public enum Paint: Equatable {
    case none
    case currentColor(NotNeeded) // Used for animations
    case rgb(Color)
    case funciri(id: String)
  }

  public enum FillRule: String, CaseIterable {
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

  public enum Units: String, CaseIterable {
    case userSpaceOnUse, objectBoundingBox
  }

  public enum FilterPrimitiveIn: Equatable {
    public enum Predefined: String, CaseIterable {
      case sourcegraphic = "SourceGraphic"
      case sourcealpha = "SourceAlpha"
      case backgroundimage = "BackgroundImage"
      case backgroundalpha = "BackgroundAlpha"
      case fillpaint = "FillPaint"
      case strokepaint = "StrokePaint"
    }

    case predefined(Predefined)
    case previous(String)
  }

  public enum BlendMode: String, CaseIterable {
    case normal, multiply, screen, darken, lighten
  }

  public enum ColorInterpolation: String, CaseIterable {
    case sRGB, linearRGB
  }

  // MARK: Attribute group

  public struct CoreAttributes: Equatable {
    public var id: String?

    public init(id: String?) {
      self.id = id
    }
  }

  public enum LineCap: String, CaseIterable {
    case butt, round, square
  }

  public enum LineJoin: String, CaseIterable {
    case miter, round, bevel
  }

  public struct PresentationAttributes: Equatable {
    public var clipPath: String?
    public var clipRule: FillRule?
    public var mask: String?
    public var filter: String?
    public var fill: Paint?
    public var fillRule: FillRule?
    public var fillOpacity: Float?
    public var stroke: Paint?
    public var strokeWidth: Length?
    public var strokeLineCap: LineCap?
    public var strokeLineJoin: LineJoin?
    public var strokeDashArray: [Length]?
    public var strokeDashOffset: Length?
    public var strokeOpacity: Float?
    public var opacity: SVG.Float?
    public var stopColor: SVG.Color?
    public var stopOpacity: SVG.Float?
    public var colorInterpolationFilters: ColorInterpolation?

    public init(
      clipPath: String?,
      clipRule: FillRule?,
      mask: String?,
      filter: String?,
      fill: Paint?,
      fillRule: FillRule?,
      fillOpacity: Float?,
      stroke: Paint?,
      strokeWidth: Length?,
      strokeLineCap: LineCap?,
      strokeLineJoin: LineJoin?,
      strokeDashArray: [Length]?,
      strokeDashOffset: Length?,
      strokeOpacity: Float?,
      opacity: Float?,
      stopColor: SVG.Color?,
      stopOpacity: SVG.Float?,
      colorInterpolationFilters: ColorInterpolation?
    ) {
      self.clipPath = clipPath
      self.clipRule = clipRule
      self.mask = mask
      self.filter = filter
      self.fill = fill
      self.fillRule = fillRule
      self.fillOpacity = fillOpacity
      self.stroke = stroke
      self.strokeWidth = strokeWidth
      self.strokeLineCap = strokeLineCap
      self.strokeLineJoin = strokeLineJoin
      self.strokeDashArray = strokeDashArray
      self.strokeDashOffset = strokeDashOffset
      self.strokeOpacity = strokeOpacity
      self.opacity = opacity
      self.stopColor = stopColor
      self.stopOpacity = stopOpacity
      self.colorInterpolationFilters = colorInterpolationFilters
    }
  }

  public struct FilterPrimitiveCommonAttributes: Equatable {
    var result: String?
    var height: Length?
    var width: Length?
    var x: Coordinate?
    var y: Coordinate?
  }

  // MARK: Content group

  public enum FilterPrimitiveContent: Equatable {
    case feBlend(FeBlend)
    case feColorMatrix(FeColorMatrix)
    case feComponentTransfer(NotImplemented)
    case feComposite(NotImplemented)
    case feConvolveMatrix(NotImplemented)
    case feDiffuseLighting(NotImplemented)
    case feDisplacementMap(NotImplemented)
    case feFlood(FeFlood)
    case feGaussianBlur(FeGaussianBlur)
    case feImage(NotImplemented)
    case feMerge(NotImplemented)
    case feMorphology(NotImplemented)
    case feOffset(FeOffset)
    case feSpecularLighting(NotImplemented)
    case feTile(NotImplemented)
    case feTurbulence(NotImplemented)
  }

  // MARK: Elements

  public struct Document: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var width: Length?
    public var height: Length?
    public var viewBox: ViewBox?
    public var children: [SVG]

    public init(
      core: CoreAttributes,
      presentation: PresentationAttributes,
      width: Length?,
      height: Length?,
      viewBox: ViewBox?,
      children: [SVG]
    ) {
      self.core = core
      self.presentation = presentation
      self.width = width
      self.height = height
      self.viewBox = viewBox
      self.children = children
    }
  }

  public struct ShapeElement<T: Equatable>: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var data: T

    @inlinable
    public init(
      core: CoreAttributes,
      presentation: PresentationAttributes,
      transform: [Transform]?,
      data: T
    ) {
      self.core = core
      self.presentation = presentation
      self.transform = transform
      self.data = data
    }
  }

  public struct RectData: Equatable {
    public var x: Coordinate?
    public var y: Coordinate?
    public var rx: Length?
    public var ry: Length?
    public var width: Coordinate?
    public var height: Coordinate?

    public init(
      x: SVG.Coordinate?,
      y: SVG.Coordinate?,
      rx: Length?,
      ry: Length?,
      width: SVG.Coordinate?,
      height: SVG.Coordinate?
    ) {
      self.x = x
      self.y = y
      self.rx = rx
      self.ry = ry
      self.width = width
      self.height = height
    }
  }

  public struct CircleData: Equatable {
    public var cx: Coordinate?
    public var cy: Coordinate?
    public var r: Length?
  }

  public struct EllipseData: Equatable {
    public var cx: Coordinate?
    public var cy: Coordinate?
    public var rx: Length?
    public var ry: Length?
  }

  public struct PathData: Equatable {
    public enum Positioning {
      case relative
      case absolute
    }

    public enum DrawTo: Equatable {
      case closepath
      case lineto(Positioning, CoordinatePair)
      case horizontalLineto(Positioning, Float)
      case verticalLineto(Positioning, Float)
      case curveto(Positioning, cp1: CoordinatePair, cp2: CoordinatePair, to: CoordinatePair)
      case smoothCurveto(Positioning, cp2: CoordinatePair, to: CoordinatePair)
      case quadraticBezierCurveto(Positioning, cp1: CoordinatePair, to: CoordinatePair)
      case smoothQuadraticBezierCurveto(Positioning, to: CoordinatePair)
      case ellepticalArc(NotImplemented)
    }

    public struct MoveTo: Equatable {
      public var pos: Positioning
      public var coordinatePair: CoordinatePair
    }

    public struct Group: Equatable {
      public var moveTo: [MoveTo]
      public var drawTo: [DrawTo]
    }

    public var d: [Group]?
    public var pathLength: Float?
  }

  public struct PolygonData: Equatable {
    public var points: [CoordinatePair]?
  }

  public typealias Path = ShapeElement<PathData>
  public typealias Rect = ShapeElement<RectData>
  public typealias Circle = ShapeElement<CircleData>
  public typealias Ellipse = ShapeElement<EllipseData>
  public typealias Line = ShapeElement<NotImplemented>
  public typealias Polyline = ShapeElement<NotImplemented>
  public typealias Polygon = ShapeElement<PolygonData>

  public struct Group: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var children: [SVG]

    public init(
      core: CoreAttributes,
      presentation: PresentationAttributes,
      transform: [Transform]?,
      children: [SVG]
    ) {
      self.core = core
      self.presentation = presentation
      self.transform = transform
      self.children = children
    }
  }

  public struct Use: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var x: Coordinate?
    public var y: Coordinate?
    public var width: Length?
    public var height: Length?
    public var xlinkHref: String?
  }

  public struct Defs: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var children: [SVG]
  }

  public struct Mask: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var x: Coordinate?
    public var y: Coordinate?
    public var width: Length?
    public var height: Length?
    public var maskUnits: Units?
    public var maskContentUnits: Units?
    public var children: [SVG]
  }

  public struct ClipPath: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var clipPathUnits: Units?
    public var children: [SVG]
  }

  public struct Stop: Equatable {
    public enum Offset: Equatable {
      case number(SVG.Float)
      case percentage(SVG.Float)
    }

    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var offset: Offset?
  }

  public struct LinearGradient: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var unit: Units?
    public var x1: Coordinate?
    public var y1: Coordinate?
    public var x2: Coordinate?
    public var y2: Coordinate?
    public var stops: [Stop]
  }

  public struct RadialGradient: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var unit: Units?
    public var cx: Coordinate?
    public var cy: Coordinate?
    public var r: Length?
    public var fx: Coordinate?
    public var fy: Coordinate?
    public var gradientTransform: [Transform]?
    public var stops: [Stop]
  }

  @dynamicMemberLookup
  public struct FilterPrimitiveElement<T: Equatable>: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var common: FilterPrimitiveCommonAttributes
    public var data: T

    @inlinable
    public init(
      core: CoreAttributes,
      presentation: PresentationAttributes,
      common: FilterPrimitiveCommonAttributes,
      data: T
    ) {
      self.core = core
      self.presentation = presentation
      self.common = common
      self.data = data
    }

    @inlinable
    public subscript<U>(dynamicMember kp: KeyPath<T, U>) -> U {
      data[keyPath: kp]
    }
  }

  public struct FilterPrimitiveFeBlend: Equatable {
    var `in`: FilterPrimitiveIn?
    var in2: FilterPrimitiveIn?
    var mode: BlendMode?
  }

  public typealias FeBlend = FilterPrimitiveElement<FilterPrimitiveFeBlend>

  public struct FilterPrimitiveFeColorMatrix: Equatable {
    public enum Kind: String, CaseIterable {
      case matrix
      case saturate
      case hueRotate
      case luminanceToAlpha
    }

    var `in`: FilterPrimitiveIn?
    var type: Kind?
    var values: [Float]?
  }

  public typealias FeColorMatrix = FilterPrimitiveElement<FilterPrimitiveFeColorMatrix>

  public struct FilterPrimitiveFeFlood: Equatable {
    var floodColor: Color?
    var floodOpacity: Float?
  }

  public typealias FeFlood = FilterPrimitiveElement<FilterPrimitiveFeFlood>

  public struct FilterPrimitiveFeGaussianBlur: Equatable {
    public var `in`: FilterPrimitiveIn?
    public var stdDeviation: NumberOptionalNumber?
  }

  public typealias FeGaussianBlur = FilterPrimitiveElement<FilterPrimitiveFeGaussianBlur>

  public struct FilterPrimitiveFeOffset: Equatable {
    public var `in`: FilterPrimitiveIn?
    public var dx: Float?
    public var dy: Float?
  }

  public typealias FeOffset = FilterPrimitiveElement<FilterPrimitiveFeOffset>

  @dynamicMemberLookup
  public struct ElementWithChildren<Attributes: Equatable, Child: Equatable>: Equatable {
    public var attributes: Attributes
    public var children: [Child]

    @inlinable
    public subscript<T>(dynamicMember kp: KeyPath<Attributes, T>) -> T {
      attributes[keyPath: kp]
    }
  }

  public struct FilterAttributes: Equatable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var x: Coordinate?
    public var y: Coordinate?
    public var width: Length?
    public var height: Length?
    public var filterUnits: Units?
  }

  public typealias Filter = ElementWithChildren<FilterAttributes, FilterPrimitiveContent>

  case svg(Document)
  case group(Group)
  case use(Use)

  case path(Path)
  case rect(Rect)
  case circle(Circle)
  case ellipse(Ellipse)
  case line(NotImplemented)
  case polyline(NotImplemented)
  case polygon(Polygon)

  case mask(Mask)
  case clipPath(ClipPath)
  case defs(Defs)
  case title(String)
  case desc(String)
  case linearGradient(LinearGradient)
  case radialGradient(RadialGradient)
  case filter(Filter)
}

// MARK: - Categories

extension SVG {
  public enum Shape {
    case path(Path)
    case rect(Rect)
    case circle(Circle)
    case ellipse(Ellipse)
    case line(NotImplemented)
    case polyline(NotImplemented)
    case polygon(Polygon)
  }

  public var shape: Shape? {
    switch self {
    case let .path(e):
      return .path(e)
    case let .rect(e):
      return .rect(e)
    case let .circle(e):
      return .circle(e)
    case let .ellipse(e):
      return .ellipse(e)
    case let .line(e):
      return .line(e)
    case let .polyline(e):
      return .polyline(e)
    case let .polygon(e):
      return .polygon(e)
    default:
      return nil
    }
  }
}

// MARK: - Serialization

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

// MARK: - Parser

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

  private typealias ParserForAttribute<T> = (Attribute) -> AttributeParser<T>
  private typealias AttributeParser<T> = Base.Parser<[String: String], T?>
  private typealias AttributeGroupParser<T> = Base.Parser<[String: String], T>

  private static var len: ParserForAttribute<SVG.Length> {
    attributeParser(SVGAttributeParsers.length)
  }

  private static var coord: ParserForAttribute<SVG.Coordinate> {
    attributeParser(SVGAttributeParsers.length)
  }

  private static var color: ParserForAttribute<SVG.Color> {
    attributeParser(SVGAttributeParsers.rgbcolor)
  }

  private static var paint: ParserForAttribute<SVG.Paint> {
    attributeParser(SVGAttributeParsers.paint)
  }

  private static var viewBox: ParserForAttribute<SVG.ViewBox> {
    attributeParser(SVGAttributeParsers.viewBox)
  }

  private static let num = attributeParser(SVGAttributeParsers.number)
  private static let numList =
    attributeParser(SVGAttributeParsers.listOfNumbers)
  private static let numberOptionalNumber =
    attributeParser(SVGAttributeParsers.numberOptionalNumber)

  private static var identifier: ParserForAttribute<String> {
    attributeParser(SVGAttributeParsers.identifier)
  }

  private static var transform: ParserForAttribute<[SVG.Transform]> {
    attributeParser(SVGAttributeParsers.transformsList)
  }

  private static var listOfPoints: ParserForAttribute<SVG.CoordinatePairs> {
    attributeParser(SVGAttributeParsers.listOfPoints)
  }

  private static let pathData = attributeParser(SVGAttributeParsers.pathData)

  private static var stopOffset: ParserForAttribute<SVG.Stop.Offset> {
    attributeParser(SVGAttributeParsers.stopOffset)
  }

  private static var fillRule: ParserForAttribute<SVG.FillRule> {
    attributeParser(oneOf(SVG.FillRule.self))
  }

  private static var version: AttributeGroupParser<Void> {
    identifier(.version).flatMapResult {
      $0.map { $0 == "1.1" ? .success(()) : .failure(Error.invalidVersion($0))
      } ?? .success(())
    }
  }

  private static let lineCap = attributeParser(oneOf(SVG.LineCap.self))
  private static let lineJoin = attributeParser(oneOf(SVG.LineJoin.self))
  private static let funciri = attributeParser(SVGAttributeParsers.funciri)
  private static let x = coord(.x)
  private static let y = coord(.y)
  private static let width = len(.width)
  private static let height = len(.height)
  private static let colorInterpolation =
    attributeParser(oneOf(SVG.ColorInterpolation.self))

  private static var xml: AttributeGroupParser<Void> {
    zip(identifier(.xmlns), identifier(.xmlnsxlink)) { _, _ in () }
  }

  private static let ignoreAttribute = attributeParser(consume(while: always(true)))
  private static let ignore: AttributeGroupParser<Void> =
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

  private static let core = identifier(.id).map(SVG.CoreAttributes.init)

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
    ) <<~ version <<~ xml <<~ endof()).run(el.attrs).get()
    return .init(
      core: attrs.0,
      presentation: attrs.1,
      width: attrs.2,
      height: attrs.3,
      viewBox: attrs.4,
      children: try el.children.map(element(from:))
    )
  }

  private static func shape<T>(
    _ parser: AttributeGroupParser<T>
  ) -> AttributeGroupParser<SVG.ShapeElement<T>> {
    zip(
      core, presentation, transform(.transform), parser,
      with: SVG.ShapeElement<T>.init
    )
  }

  private static let rect = shape(zip(
    x, y, len(.rx), len(.ry),
    width, height,
    with: SVG.RectData.init
  ))
  private static let polygon = shape(
    listOfPoints(.points).map(SVG.PolygonData.init)
  )
  private static let circle = shape(zip(
    coord(.cx), coord(.cy), coord(.r),
    with: SVG.CircleData.init
  ))
  private static let ellipse = shape(zip(
    coord(.cx), coord(.cy), len(.rx), len(.ry),
    with: SVG.EllipseData.init
  ))
  private static let path = shape(zip(
    pathData(.d), num(.pathLength), with: SVG.PathData.init
  ))

  public static func rect(from el: XML.Element) throws -> SVG.Rect {
    try (rect <<~ endof()).run(el.attrs).get()
  }

  public static func group(from el: XML.Element) throws -> SVG.Group {
    let attrs = try (zip(
      core, presentation, transform(.transform), with: identity
    ) <<~ endof()).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      children: el.children.map(element(from:))
    )
  }

  public static func defs(from el: XML.Element) throws -> SVG.Defs {
    let attrs = try (zip(core, presentation, transform(.transform), with: identity) <<~ endof())
      .run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      children: el.children.map(element(from:))
    )
  }

  public static func polygon(from el: XML.Element) throws -> SVG.Polygon {
    try (polygon <<~ endof()).run(el.attrs).get()
  }

  public static func circle(from el: XML.Element) throws -> SVG.Circle {
    try (circle <<~ endof()).run(el.attrs).get()
  }

  public static func ellipse(from el: XML.Element) throws -> SVG.Ellipse {
    try (ellipse <<~ endof()).run(el.attrs).get()
  }

  private static var stop: AttributeGroupParser<SVG.Stop> {
    zip(core, presentation, stopOffset(.offset), with: SVG.Stop.init)
  }

  public static func stops(from el: XML.Element) throws -> SVG.Stop {
    try (stop <<~ endof()).run(el.attrs).get()
  }

  private static let units = attributeParser(oneOf(SVG.Units.self))

  public static func linearGradient(from el: XML.Element) throws -> SVG.LinearGradient {
    let attrs = try (zip(
      core, presentation, units(.gradientUnits),
      coord(.x1), coord(.y1), coord(.x2), coord(.y2),
      with: identity
    ) <<~ endof()).run(el.attrs).get()
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
      stops: subelements.map(stops(from:))
    )
  }

  public static func radialGradient(from el: XML.Element) throws -> SVG.RadialGradient {
    let attrs = try (zip(
      core, presentation, units(.gradientUnits),
      coord(.cx), coord(.cy), len(.r),
      coord(.fx), coord(.fy), transform(.gradientTransform),
      with: identity
    ) <<~ endof()).run(el.attrs).get()
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
    try (path <<~ endof()).run(el.attrs).get()
  }

  private static let iri: ParserForAttribute<String> = attributeParser(SVGAttributeParsers.iri)
  private static let use: AttributeGroupParser<SVG.Use> = zip(
    core, presentation,
    transform(.transform),
    x, y, width, height,
    iri(.xlinkHref),
    with: SVG.Use.init
  )
  public static func use(from el: XML.Element) throws -> SVG.Use {
    try (use <<~ endof()).run(el.attrs).get()
  }

  public static func mask(from el: XML.Element) throws -> SVG.Mask {
    let attrs = try (zip(
      core, presentation,
      transform(.transform),
      x, y, width, height,
      units(.maskUnits), units(.maskContentUnits),
      with: identity
    ) <<~ ignore <<~ endof()).run(el.attrs).get()
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
    ) <<~ endof()).run(el.attrs).get()
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      transform: attrs.2,
      clipPathUnits: attrs.3,
      children: el.children.map(element(from:))
    )
  }

  private static let filterAttributes: AttributeGroupParser<SVG.FilterAttributes> = zip(
    core, presentation,
    x, y, width, height, units(.filterUnits),
    with: SVG.FilterAttributes.init
  )

  private static func elementWithChildren<Attributes, Child>(
    attributes: AttributeGroupParser<Attributes>,
    child: Parser<XML, Child>
  ) -> Parser<XML, SVG.ElementWithChildren<Attributes, Child>> {
    let childParser = Parser<ArraySlice<XML>, Child>.next { child.run($0) }
    let childrenParser: Parser<[XML], [Child]> =
      (childParser* <<~ endof())
      .pullback(get: { $0[...] }, set: { $0 = Array($1) })
    let attrs = (attributes <<~ endof())
    return zip(
      attrs.pullback(\XML.Element.attrs),
      childrenParser.pullback(\XML.Element.children),
      with: SVG.ElementWithChildren.init
    ).optional.pullback(\XML.el)
  }

  private static func element<Attributes>(
    tag: Tag
  ) -> (AttributeGroupParser<Attributes>) -> Parser<XML, Attributes> {
    let tag: Parser<XML.Element, Void> =
      consume(tag.rawValue)
      .pullback(get: { $0[...] }, set: { $0 = String($1) })
      .pullback(\XML.Element.tag)
    return { attributes in
      (tag ~>> (attributes <<~ endof()).pullback(\.attrs))
        .optional.pullback(\.el)
    }
  }

  private static let filterPrimitiveAttributes = zip(
    identifier(.result),
    height, width, x, y,
    with: SVG.FilterPrimitiveCommonAttributes.init
  )

  private static func filterPrimitive<T>(
    _ data: AttributeGroupParser<T>
  ) -> AttributeGroupParser<SVG.FilterPrimitiveElement<T>> {
    zip(
      core, presentation, filterPrimitiveAttributes, data,
      with: SVG.FilterPrimitiveElement.init
    )
  }

  private static let filterPrimitiveIn =
    attributeParser(SVGAttributeParsers.filterPrimitiveIn)
  private static let blendMode = attributeParser(SVGAttributeParsers.blendMode)
  private static let feColorMatrixType =
    attributeParser(oneOf(SVG.FilterPrimitiveFeColorMatrix.Kind.self))

  private static let feBlend = zip(
    filterPrimitiveIn(.in),
    filterPrimitiveIn(.in2),
    blendMode(.mode),
    with: SVG.FilterPrimitiveFeBlend.init
  ) |> filterPrimitive >>> element(tag: .feBlend)

  private static let feColorMatrix = zip(
    filterPrimitiveIn(.in),
    feColorMatrixType(.type),
    numList(.values),
    with: SVG.FilterPrimitiveFeColorMatrix.init
  ) |> filterPrimitive >>> element(tag: .feColorMatrix)

  private static let feFlood = zip(
    color(.floodColor),
    num(.floodOpacity),
    with: SVG.FilterPrimitiveFeFlood.init
  ) |> filterPrimitive >>> element(tag: .feFlood)

  private static let feGaussianBlur = zip(
    filterPrimitiveIn(.in),
    numberOptionalNumber(.stdDeviation),
    with: SVG.FilterPrimitiveFeGaussianBlur.init
  ) |> filterPrimitive >>> element(tag: .feGaussianBlur)

  private static let feOffset = zip(
    filterPrimitiveIn(.in),
    num(.dx),
    num(.dy),
    with: SVG.FilterPrimitiveFeOffset.init
  ) |> filterPrimitive >>> element(tag: .feOffset)

  private static let filterPrimitiveContent: Parser<XML, SVG.FilterPrimitiveContent> = oneOf([
    feBlend.map(SVG.FilterPrimitiveContent.feBlend),
    feColorMatrix.map(SVG.FilterPrimitiveContent.feColorMatrix),
    feFlood.map(SVG.FilterPrimitiveContent.feFlood),
    feGaussianBlur.map(SVG.FilterPrimitiveContent.feGaussianBlur),
    feOffset.map(SVG.FilterPrimitiveContent.feOffset),
  ])

  private static let filter: Parser<XML, SVG.Filter> = elementWithChildren(
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
  _ parser: SVGAttributeParsers.Parser<T>
) -> (Attribute) -> Parser<[String: String], T?> {
  {
    key(key: $0.rawValue)~?.flatMapResult {
      guard let value = $0 else { return .success(nil) }
      return parser.map(Optional.some).whole(value)
    }
  }
}

public enum SVGAttributeParsers {
  typealias Parser<T> = Base.Parser<Substring, T>
  internal static let wsp: Parser<Void> = oneOf([0x20, 0x9, 0xD, 0xA]
    .map(Unicode.Scalar.init).map(Character.init)
    .map(consume)
  )
  internal static let comma: Parser<Void> = ","

  // (wsp+ comma? wsp*) | (comma wsp*)
  internal static let commaWsp: Parser<Void> =
    (wsp+ ~>> comma~? ~>> wsp* | comma ~>> wsp*).map(always(()))
  internal static let number: Parser<SVG.Float> = double()
  internal static let listOfNumbers = zeroOrMore(number, separator: commaWsp)
  internal static let numberOptionalNumber = zip(number, (commaWsp ~>> number)~?, with: SVG.NumberOptionalNumber.init)
  internal static let coord: Parser<SVG.Float> = number

  internal static let lengthUnit: Parser<SVG.Length.Unit> = oneOf()
  internal static let length: Parser<SVG.Length> = (number ~ lengthUnit~?)
    .map { SVG.Length(number: $0.0, unit: $0.1) }

  internal static let viewBox: Parser<SVG.ViewBox> =
    zip(
      number <<~ commaWsp, number <<~ commaWsp, number <<~ commaWsp, number,
      with: SVG.ViewBox.init
    )

  // Has no equivalent in specification, for code deduplication only.
  // "$name" wsp* "(" wsp* parser wsp* ")"
  internal static func namedTransform(
    _ name: String,
    _ value: Parser<SVG.Transform>
  ) -> Parser<SVG.Transform> {
    (consume(name) ~ wsp* ~ "(" ~ wsp*) ~>> value <<~ (wsp* ~ ")")
  }

  // "translate" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  internal static let translate: Parser<SVG.Transform> = namedTransform(
    "translate",
    zip(number, (commaWsp ~>> number)~?, with: SVG.Transform.translate)
  )

  // "scale" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  internal static let scale: Parser<SVG.Transform> = namedTransform(
    "scale",
    zip(number, (commaWsp ~>> number)~?, with: SVG.Transform.scale)
  )

  // comma-wsp number comma-wsp number
  private static let anchor: Parser<SVG.Transform.Anchor> = zip(
    commaWsp ~>> number, commaWsp ~>> number,
    with: SVG.Transform.Anchor.init
  )

  // "rotate" wsp* "(" wsp* number ( comma-wsp number comma-wsp number )? wsp* ")"
  internal static let rotate: Parser<SVG.Transform> = namedTransform(
    "rotate",
    zip(number, anchor~?, with: SVG.Transform.rotate)
  )

  internal static let transformsList: Parser<[SVG.Transform]> =
    wsp* ~>> oneOrMore(transform, separator: commaWsp+) <<~ wsp*
  internal static let transform: Parser<SVG.Transform> = oneOf([
    translate,
    scale,
    rotate,
  ])

  internal static let hexByteFromSingle: Parser<UInt8> = readOne().flatMap {
    guard let value = hexFromChar($0) else { return .never() }
    return .always(value << 4 | value)
  }

  internal static let hexByte: Parser<UInt8> = (readOne() ~ readOne()).flatMap {
    guard let v1 = hexFromChar($0.0), let v2 = hexFromChar($0.1) else { return .never() }
    return .always(v1 << 4 | v2)
  }

  private static let shortRGB: Parser<SVG.Color> =
    zip(hexByteFromSingle, hexByteFromSingle, hexByteFromSingle, with: SVG.Color.init)
  private static let rgb: Parser<SVG.Color> = zip(hexByte, hexByte, hexByte, with: SVG.Color.init)

  public static let rgbcolor = oneOf([
    "#" ~>> (rgb | shortRGB),
    oneOf(SVGColorKeyword.self).map(get(\.color)),
  ])

  internal static let iri: Parser<String> =
    "#" ~>> consume(while: always(true)).map(String.init)
  internal static let funciri: Parser<String> =
    "url(#" ~>> consume(while: { $0 != ")" }).map(String.init) <<~ ")"

  internal static let paint: Parser<SVG.Paint> =
    consume("none").map(always(.none)) |
    rgbcolor.map(SVG.Paint.rgb) |
    funciri.map(SVG.Paint.funciri(id:))

  // coordinate comma-wsp coordinate
  // | coordinate negative-coordinate
  private static let coordinatePair: Parser<SVG.CoordinatePair> =
    (number <<~ commaWsp~? ~ number).map(SVG.CoordinatePair.init)

  // list-of-points:
  //   wsp* coordinate-pairs? wsp*
  // coordinate-pairs:
  //   coordinate-pair
  //   | coordinate-pair comma-wsp coordinate-pairs
  internal static let listOfPoints: Parser<SVG.CoordinatePairs> =
    wsp* ~>> zeroOrMore(coordinatePair, separator: commaWsp) <<~ wsp*

  internal static let identifier: Parser<String> =
    Parser<Substring>.identity().map(String.init)

  internal static let stopOffset: Parser<SVG.Stop.Offset> = (number ~ "%"~?).map {
    switch $0.1 {
    case .some:
      return .percentage($0.0)
    case nil:
      return .number($0.0)
    }
  }

  // MARK: Path

  private static let moveto: Parser<[SVG.PathData.MoveTo]> =
    command("M", arg: coordinatePair) { .init(pos: $0, coordinatePair: $1) }

  private static let drawToCommand: Parser<[SVG.PathData.DrawTo]> = oneOf([
    (positioning(of: "Z") <<~ wsp*).map(always([.closepath])),
    drawto("L", arg: coordinatePair, builder: SVG.PathData.DrawTo.lineto),
    drawto("H", arg: coord) { .horizontalLineto($0, $1) },
    drawto("V", arg: coord) { .verticalLineto($0, $1) },
    drawto("C", arg: threeCoordinatePairs) { .curveto($0, cp1: $1.0, cp2: $1.1, to: $1.2) },
    drawto("S", arg: twoCoordinatePairs) { .smoothCurveto($0, cp2: $1.0, to: $1.1) },
    drawto("Q", arg: twoCoordinatePairs) { .quadraticBezierCurveto($0, cp1: $1.0, to: $1.1) },
    drawto("T", arg: coordinatePair) { .smoothQuadraticBezierCurveto($0, to: $1) },
    drawto("A", arg: Parser<Never>.never(), builder: absurd),
  ])

  private static let pathCommandGroup: Parser<SVG.PathData.Group> =
    (moveto <<~ wsp* ~ zeroOrMore(drawToCommand, separator: wsp*)).map {
      SVG.PathData.Group(moveTo: $0.0, drawTo: $0.1.flatMap(identity))
    }

  internal static let pathData =
    wsp* ~>> oneOrMore(pathCommandGroup, separator: wsp*) <<~ wsp*

  private static let twoCoordinatePairs = zip(
    coordinatePair <<~ commaWsp~?,
    coordinatePair,
    with: identity
  )
  private static let threeCoordinatePairs = zip(
    coordinatePair <<~ commaWsp~?,
    coordinatePair <<~ commaWsp~?,
    coordinatePair,
    with: identity
  )

  private static func command<T, V>(
    _ cmd: Character,
    arg: Parser<T>,
    builder: @escaping (SVG.PathData.Positioning, T) -> V
  ) -> Parser<[V]> {
    zip(
      positioning(of: cmd) <<~ wsp*,
      argumentSequence(arg)
    ) { pos, args in
      args.map { builder(pos, $0) }
    }
  }

  private static func drawto<T>(
    _ cmd: Character,
    arg: Parser<T>,
    builder: @escaping (SVG.PathData.Positioning, T) -> SVG.PathData.DrawTo
  ) -> Parser<[SVG.PathData.DrawTo]> {
    command(cmd, arg: arg, builder: builder)
  }

  private static func positioning(
    of cmd: Character
  ) -> Parser<SVG.PathData.Positioning> {
    consume(cmd.lowercased()).map(always(.relative))
      | consume(cmd.uppercased()).map(always(.absolute))
  }

  private static func argumentSequence<T>(_ p: Parser<T>) -> Parser<[T]> {
    oneOrMore(p, separator: commaWsp~?)
  }

  private static func hexFromChar(_ c: Character) -> UInt8? {
    c.hexDigitValue.flatMap(UInt8.init(exactly:))
  }

  // Dash Array
  internal static let dashArray = oneOrMore(length, separator: commaWsp)

  private static let filterPrimitiveInPredefined:
    Parser<SVG.FilterPrimitiveIn.Predefined> = oneOf()

  internal static let filterPrimitiveIn: Parser<SVG.FilterPrimitiveIn> = Parser<Substring>.identity()
    .map {
      let value = String($0)
      return SVG.FilterPrimitiveIn.Predefined(rawValue: value)
        .map(SVG.FilterPrimitiveIn.predefined) ?? .previous(value)
    }

  internal static let blendMode: Parser<SVG.BlendMode> = oneOf()
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
