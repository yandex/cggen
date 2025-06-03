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
