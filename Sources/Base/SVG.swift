import CoreGraphics
import Foundation

@preconcurrency import Parsing

// https://www.w3.org/TR/SVG11/
public enum SVG: Equatable, Sendable {
  public typealias NotImplemented = Never
  public typealias NotNeeded = Never

  // MARK: Attributes

  public typealias Float = Swift.Double
  public typealias Color = RGBColor<UInt8>

  public struct Length: Equatable, Sendable {
    public enum Unit: String, CaseIterable, Sendable {
      case px, pt
      case percent = "%"
    }

    public var number: Float
    public var unit: Unit?
  }

  public typealias Coordinate = SVG.Length

  // Should be tuple, when Equatable synthesys improves
  // https://bugs.swift.org/browse/SR-1222
  public struct CoordinatePair: Equatable, Sendable {
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

  public struct Angle: Equatable, Sendable {
    public var degrees: Float
  }

  public typealias CoordinatePairs = [CoordinatePair]

  public struct ViewBox: Equatable, Sendable {
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

  public enum Transform: Equatable, Sendable {
    public struct Anchor: Equatable, Sendable {
      public var cx: Float
      public var cy: Float
    }

    case matrix(a: Float, b: Float, c: Float, d: Float, e: Float, f: Float)
    case translate(tx: Float, ty: Float?)
    case scale(sx: Float, sy: Float?)
    case rotate(angle: Angle, anchor: Anchor?)
    case skewX(Angle)
    case skewY(Angle)
  }

  public enum Units: String, CaseIterable, Sendable {
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

  public enum BlendMode: String, CaseIterable, Sendable {
    case normal, multiply, screen, darken, lighten
  }

  public enum ColorInterpolation: String, CaseIterable {
    case sRGB, linearRGB
  }

  // MARK: Attribute group

  public struct CoreAttributes: Equatable, Sendable {
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

  public struct PresentationAttributes: Equatable, @unchecked Sendable {
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

  public struct Document: Equatable, Sendable {
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

  public struct ShapeElement<T: Equatable & Sendable>: Equatable, Sendable {
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

  public struct RectData: Equatable, Sendable {
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

  public struct CircleData: Equatable, Sendable {
    public var cx: Coordinate?
    public var cy: Coordinate?
    public var r: Length?
  }

  public struct EllipseData: Equatable, Sendable {
    public var cx: Coordinate?
    public var cy: Coordinate?
    public var rx: Length?
    public var ry: Length?
  }

  public struct PathData: Equatable, Sendable {
    public enum Positioning: Sendable, Equatable {
      case relative
      case absolute
    }

    public struct CurveArgument: Equatable {
      public var cp1: CoordinatePair
      public var cp2: CoordinatePair
      public var to: CoordinatePair
    }

    public struct SmoothCurveArgument: Equatable {
      public var cp2: CoordinatePair
      public var to: CoordinatePair
    }

    public struct QuadraticCurveArgument: Equatable {
      public var cp1: CoordinatePair
      public var to: CoordinatePair
    }

    /*
     8.3.8 The elliptical arc curve commands
     */
    public struct EllipticalArcArgument: Equatable {
      public var rx: Float
      public var ry: Float
      public var xAxisRotation: Float
      public var largeArcFlag: Bool
      public var sweepFlag: Bool
      public var end: CoordinatePair

      public typealias Destructed = (
        rx: Float, ry: Float, xAxisRotation: Float,
        largeArcFlag: Bool, sweepFlag: Bool,
        end: CoordinatePair
      )
      @inlinable
      public func destruct() -> Destructed {
        (rx, ry, xAxisRotation, largeArcFlag, sweepFlag, end)
      }
    }

    public enum CommandKind: Equatable, @unchecked Sendable {
      case closepath
      case moveto([CoordinatePair])
      case lineto([CoordinatePair])
      case horizontalLineto([Float])
      case verticalLineto([Float])
      case curveto([CurveArgument])
      case smoothCurveto([SmoothCurveArgument])
      case quadraticBezierCurveto([QuadraticCurveArgument])
      case smoothQuadraticBezierCurveto(to: [CoordinatePair])
      case ellipticalArc([EllipticalArcArgument])
    }

    public struct Command: Equatable, Sendable {
      public var positioning: Positioning
      public var kind: CommandKind
    }

    public var d: [Command]?
    public var pathLength: Float?
  }

  public struct PolygonData: Equatable, Sendable {
    public var points: [CoordinatePair]?
  }

  public typealias Path = ShapeElement<PathData>
  public typealias Rect = ShapeElement<RectData>
  public typealias Circle = ShapeElement<CircleData>
  public typealias Ellipse = ShapeElement<EllipseData>
  public typealias Line = ShapeElement<NotImplemented>
  public typealias Polyline = ShapeElement<NotImplemented>
  public typealias Polygon = ShapeElement<PolygonData>

  public struct Group: Equatable, Sendable {
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

  public struct Use: Equatable, Sendable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var x: Coordinate?
    public var y: Coordinate?
    public var width: Length?
    public var height: Length?
    public var xlinkHref: String?
  }

  public struct Defs: Equatable, Sendable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var children: [SVG]
  }

  public struct Mask: Equatable, Sendable {
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

  public struct ClipPath: Equatable, Sendable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var transform: [Transform]?
    public var clipPathUnits: Units?
    public var children: [SVG]
  }

  public struct Stop: Equatable, Sendable {
    public enum Offset: Equatable, Sendable {
      case number(SVG.Float)
      case percentage(SVG.Float)
    }

    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var offset: Offset?
  }

  public struct LinearGradient: Equatable, Sendable {
    public var core: CoreAttributes
    public var presentation: PresentationAttributes
    public var unit: Units?
    public var x1: Coordinate?
    public var y1: Coordinate?
    public var x2: Coordinate?
    public var y2: Coordinate?
    public var gradientTransform: [Transform]?
    public var stops: [Stop]
  }

  public struct RadialGradient: Equatable, Sendable {
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

  public typealias FeColorMatrix =
    FilterPrimitiveElement<FilterPrimitiveFeColorMatrix>

  public struct FilterPrimitiveFeFlood: Equatable {
    var floodColor: Color?
    var floodOpacity: Float?
  }

  public typealias FeFlood = FilterPrimitiveElement<FilterPrimitiveFeFlood>

  public struct FilterPrimitiveFeGaussianBlur: Equatable {
    public var `in`: FilterPrimitiveIn?
    public var stdDeviation: NumberOptionalNumber?
  }

  public typealias FeGaussianBlur =
    FilterPrimitiveElement<FilterPrimitiveFeGaussianBlur>

  public struct FilterPrimitiveFeOffset: Equatable {
    public var `in`: FilterPrimitiveIn?
    public var dx: Float?
    public var dy: Float?
  }

  public typealias FeOffset = FilterPrimitiveElement<FilterPrimitiveFeOffset>

  @dynamicMemberLookup
  public struct ElementWithChildren<
    Attributes: Equatable,
    Child: Equatable
  >: Equatable, @unchecked Sendable {
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

  public typealias Filter = ElementWithChildren<
    FilterAttributes,
    FilterPrimitiveContent
  >

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

  private typealias ParserForAttribute<T> =
    @Sendable (Attribute) -> AttributeParser<T>
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

  private static let identifier: ParserForAttribute<String> =
    attributeParser(SVGAttributeParsers.identifier)

  private static let transform: ParserForAttribute<[SVG.Transform]> =
    attributeParser(SVGAttributeParsers.transformsList)

  private static let listOfPoints: ParserForAttribute<SVG.CoordinatePairs> =
    attributeParser(SVGAttributeParsers.listOfPoints)

  private static let pathData = attributeParser(SVGAttributeParsers.pathData)

  private static let stopOffset: ParserForAttribute<SVG.Stop.Offset> =
    attributeParser(SVGAttributeParsers.stopOffset)

  private static let fillRule: ParserForAttribute<SVG.FillRule> =
    attributeParser(oneOf(SVG.FillRule.self))

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

  private static let ignoreAttribute =
    attributeParser(consume(while: always(true)))
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
    return try .init(
      core: attrs.0,
      presentation: attrs.1,
      width: attrs.2,
      height: attrs.3,
      viewBox: attrs.4,
      children: el.children.map(element(from:))
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
    let attrs =
      try (
        zip(core, presentation, transform(.transform), with: identity) <<~
          endof()
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

  public static func linearGradient(
    from el: XML.Element
  ) throws -> SVG.LinearGradient {
    let attrs = try (zip(
      core, presentation, units(.gradientUnits),
      coord(.x1), coord(.y1), coord(.x2), coord(.y2),
      transform(.gradientTransform),
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

  private static let iri: ParserForAttribute<String> =
    attributeParser(SVGAttributeParsers.iri)
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

  private static
  let filterAttributes: AttributeGroupParser<SVG.FilterAttributes> = zip(
    core, presentation,
    x, y, width, height, units(.filterUnits),
    with: SVG.FilterAttributes.init
  )

  private static func elementWithChildren<Attributes, Child>(
    attributes: AttributeGroupParser<Attributes>,
    child: some NewParser<XML, Child>
  ) -> Parser<XML, SVG.ElementWithChildren<Attributes, Child>> {
    let childParser = Parser<ArraySlice<XML>, Child>.next {
      child.oldParser.run($0)
    }
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
    let tag: some NewParser<XML.Element, Void> =
      tag.rawValue.oldParser
        .pullback(\.substring)
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

  private static nonisolated(unsafe)
  let filterPrimitiveContent: some NewParser<XML, SVG.FilterPrimitiveContent> = oneOf([
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
  _ parser: some SVGAttributeParsers.NewParser<T>
) -> @Sendable (Attribute) -> Parser<[String: String], T?> {
  nonisolated(unsafe) let parser = parser
  return {
    key(key: $0.rawValue)~?.flatMapResult {
      guard let value = $0 else { return .success(nil) }
      return Result { try parser.map(Optional.some).parse(value) }
    }
  }
}

public enum SVGAttributeParsers {
  typealias Parser<T> = Base.Parser<Substring, T>
  public typealias NewParser<T> = Base.NewParser<Substring, T>

  static let comma: String = ","
  static let wsps = [0x20, 0x9, 0xD, 0xA].map { String.UTF8View([$0]) }
  static let wsp = From(.utf8) { OneOf {
    for s in wsps {
      s
    }
  }}

  // (wsp+ comma? wsp*) | (comma wsp*)
  nonisolated(unsafe)
  static let commaWsp: some NewParser<Void> =
    (wsp+ ~>> comma~? ~>> wsp* | comma ~>> wsp*).map(always(()))
  nonisolated(unsafe)
  static let number: some NewParser<SVG.Float> =
    From(.utf8) { SVG.Float.parser() }
  static let listOfNumbers = zeroOrMore(number, separator: commaWsp)
  nonisolated(unsafe)
  static let numberOptionalNumber: some NewParser<SVG.NumberOptionalNumber> = Parse {
    SVG.NumberOptionalNumber(_1: $0.0, _2: $0.1)
  } with: {
    number
    (commaWsp ~>> number)~?
  }
  nonisolated(unsafe)
  static let coord: some NewParser<SVG.Float> = number

  nonisolated(unsafe)
  static let lengthUnit: some NewParser<SVG.Length.Unit> = oneOf()
  static let length: Parser<SVG.Length> = (number ~ lengthUnit~?)
    .map { SVG.Length(number: $0.0, unit: $0.1) }
  nonisolated(unsafe)
  static let flag: some NewParser<Bool> =
    oneOf("0".map(always(false)), "1".map(always(true)))

  static let viewBox: Parser<SVG.ViewBox> =
    zip(
      number <<~ commaWsp, number <<~ commaWsp, number <<~ commaWsp, number,
      with: SVG.ViewBox.init
    )

  // Has no equivalent in specification, for code deduplication only.
  // "$name" wsp* "(" wsp* parser wsp* ")"
  static func namedTransform(
    _ name: String,
    _ value: some NewParser<SVG.Transform>
  ) -> Parser<SVG.Transform> {
    (name ~ wsp* ~ "(" ~ wsp*) ~>> value <<~ (wsp* ~ ")")
  }

  // "translate" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  static let translate: Parser<SVG.Transform> = namedTransform(
    "translate",
    zip(number, (commaWsp ~>> number)~?, with: SVG.Transform.translate)
  )

  // "scale" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  static let scale: Parser<SVG.Transform> = namedTransform(
    "scale",
    zip(number, (commaWsp ~>> number)~?, with: SVG.Transform.scale)
  )

  // comma-wsp number comma-wsp number
  private static let anchor: Parser<SVG.Transform.Anchor> = zip(
    commaWsp ~>> number, commaWsp ~>> number,
    with: SVG.Transform.Anchor.init
  )

  nonisolated(unsafe)
  private static let angle: some NewParser<SVG.Angle> =
    number.map(SVG.Angle.init)

  // "rotate" wsp* "(" wsp* number ( comma-wsp number comma-wsp number )? wsp*
  // ")"
  static let rotate: Parser<SVG.Transform> = namedTransform(
    "rotate",
    zip(angle, anchor~?, with: SVG.Transform.rotate)
  )

  // "skewX" wsp* "(" wsp* number wsp* ")"
  static let skewX: Parser<SVG.Transform> = namedTransform(
    "skewX", angle.map(SVG.Transform.skewX)
  )
  // "skewX" wsp* "(" wsp* number wsp* ")"
  static let skewY: Parser<SVG.Transform> = namedTransform(
    "skewY", angle.map(SVG.Transform.skewY)
  )

  /*
   "matrix" wsp* "(" wsp*
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number wsp* ")"
   */
  static let matrix: Parser<SVG.Transform> = namedTransform(
    "matrix", zip(
      number <<~ commaWsp,
      number <<~ commaWsp,
      number <<~ commaWsp,
      number <<~ commaWsp,
      number <<~ commaWsp,
      number,
      with: SVG.Transform.matrix
    )
  )

  static let transformsList: Parser<[SVG.Transform]> =
    wsp* ~>> oneOrMore(transform, separator: commaWsp+) <<~ wsp*
  nonisolated(unsafe)
  static let transform: some NewParser<SVG.Transform> = oneOf([
    translate,
    scale,
    rotate,
    skewX,
    skewY,
    matrix,
  ])

  static let hexByteFromSingle: Parser<UInt8> = readOne().flatMap {
    guard let value = hexFromChar($0) else { return .never() }
    return .always(value << 4 | value)
  }

  static let hexByte: Parser<UInt8> = (readOne() ~ readOne()).flatMap {
    guard let v1 = hexFromChar($0.0),
          let v2 = hexFromChar($0.1) else { return .never() }
    return .always(v1 << 4 | v2)
  }

  private static let shortRGB: Parser<SVG.Color> =
    zip(
      hexByteFromSingle,
      hexByteFromSingle,
      hexByteFromSingle,
      with: SVG.Color.init
    )
  private static let rgb: Parser<SVG.Color> = zip(
    hexByte,
    hexByte,
    hexByte,
    with: SVG.Color.init
  )

  nonisolated(unsafe)
  public static let rgbcolor: some NewParser<SVG.Color> = oneOf([
    "#" ~>> (rgb | shortRGB),
    oneOf(SVGColorKeyword.self).map(\.color),
  ])

  static let iri: Parser<String> =
    "#" ~>> consume(while: always(true)).map(String.init)
  static let funciri: Parser<String> =
    "url(#" ~>> consume(while: { $0 != ")" }).map(String.init) <<~ ")"

  static let paint: Parser<SVG.Paint> =
    "none".map(always(.none)) |
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
  static let listOfPoints: Parser<SVG.CoordinatePairs> =
    wsp* ~>> zeroOrMore(coordinatePair, separator: commaWsp) <<~ wsp*

  // elliptical-arc-argument:
  //   nonnegative-number comma-wsp? nonnegative-number comma-wsp?
  //     number comma-wsp flag comma-wsp? flag comma-wsp? coordinate-pair
  static
  let ellipticalArcArg: Parser<SVG.PathData.EllipticalArcArgument> =
    zip(
      number <<~ commaWsp~?, number <<~ commaWsp~?,
      number <<~ commaWsp, flag <<~ commaWsp~?, flag <<~ commaWsp~?,
      coordinatePair,
      with: SVG.PathData.EllipticalArcArgument.init
    )

  static let identifier: Parser<String> =
    Parser<Substring>.identity().map(String.init)

  static let stopOffset: Parser<SVG.Stop.Offset> = (number ~ "%"~?)
    .map {
      switch $0.1 {
      case .some:
        return .percentage($0.0)
      case nil:
        return .number($0.0)
      }
    }

  // MARK: Path

  nonisolated(unsafe)
  private static let anyCommand: some NewParser<SVG.PathData.Command> = oneOf([
    command("M", arg: coordinatePair) { .moveto($0) },
    command("L", arg: coordinatePair) { .lineto($0) },
    command("H", arg: coord) { .horizontalLineto($0) },
    command("V", arg: coord) { .verticalLineto($0) },
    command("C", arg: curveArgument) { .curveto($0) },
    command("S", arg: smoothCurveArgument) { .smoothCurveto($0) },
    command("Q", arg: quadraticCurveArgument) { .quadraticBezierCurveto($0) },
    command("T", arg: coordinatePair) { .smoothQuadraticBezierCurveto(to: $0) },
    command("A", arg: ellipticalArcArg) { .ellipticalArc($0) },
    positioning(of: "Z").map { .init(positioning: $0, kind: .closepath) },
  ])

  static let pathData =
    wsp* ~>> oneOrMore(anyCommand, separator: wsp*) <<~ wsp*

  private static let quadraticCurveArgument = zip(
    coordinatePair <<~ commaWsp~?,
    coordinatePair,
    with: SVG.PathData.QuadraticCurveArgument.init
  )

  private static let smoothCurveArgument = zip(
    coordinatePair <<~ commaWsp~?,
    coordinatePair,
    with: SVG.PathData.SmoothCurveArgument.init
  )

  private static let curveArgument = zip(
    coordinatePair <<~ commaWsp~?,
    coordinatePair <<~ commaWsp~?,
    coordinatePair,
    with: SVG.PathData.CurveArgument.init
  )

  private static func command<T>(
    _ cmd: Character,
    arg: some NewParser<T>,
    builder: @escaping ([T]) -> SVG.PathData.CommandKind
  ) -> Parser<SVG.PathData.Command> {
    zip(
      positioning(of: cmd) <<~ wsp*,
      argumentSequence(arg)
    ) { pos, args in
      SVG.PathData.Command(positioning: pos, kind: builder(args))
    }
  }

  private static func positioning(
    of cmd: Character
  ) -> Parser<SVG.PathData.Positioning> {
    cmd.lowercased().map(always(.relative))
      | cmd.uppercased().map(always(.absolute))
  }

  private static func argumentSequence<T>(_ p: some NewParser<T>) -> Parser<[T]> {
    oneOrMore(p, separator: commaWsp~?)
  }

  private static func hexFromChar(_ c: Character) -> UInt8? {
    c.hexDigitValue.flatMap(UInt8.init(exactly:))
  }

  // Dash Array
  static let dashArray = oneOrMore(length, separator: commaWsp)

  nonisolated(unsafe)
  private static let filterPrimitiveInPredefined:
    some NewParser<SVG.FilterPrimitiveIn.Predefined> = oneOf()

  static let filterPrimitiveIn: Parser<SVG.FilterPrimitiveIn> =
    Parser<Substring>.identity()
      .map {
        let value = String($0)
        return SVG.FilterPrimitiveIn.Predefined(rawValue: value)
          .map(SVG.FilterPrimitiveIn.predefined) ?? .previous(value)
      }

  nonisolated(unsafe)
  static let blendMode: some NewParser<SVG.BlendMode> = oneOf()
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
