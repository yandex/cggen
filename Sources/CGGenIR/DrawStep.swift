@preconcurrency import CoreGraphics

public enum DrawStep: Sendable {
  public struct RadialGradientDrawingOptions: Sendable {
    public var startCenter: CGPoint
    public var startRadius: CGFloat
    public var endCenter: CGPoint
    public var endRadius: CGFloat
    public var options: CGGradientDrawingOptions
    public var transform: CGAffineTransform?

    public init(
      startCenter: CGPoint,
      startRadius: CGFloat,
      endCenter: CGPoint,
      endRadius: CGFloat,
      options: CGGradientDrawingOptions,
      transform: CGAffineTransform? = nil
    ) {
      self.startCenter = startCenter
      self.startRadius = startRadius
      self.endCenter = endCenter
      self.endRadius = endRadius
      self.options = options
      self.transform = transform
    }
  }

  public enum Units: Sendable {
    case userSpaceOnUse, objectBoundingBox
  }

  public struct LinearGradientDrawingOptions: Sendable {
    public var startPoint: CGPoint
    public var endPoint: CGPoint
    public var options: CGGradientDrawingOptions
    public var units: Units
    public var transform: CGAffineTransform?

    public init(
      startPoint: CGPoint,
      endPoint: CGPoint,
      options: CGGradientDrawingOptions,
      units: Units,
      transform: CGAffineTransform? = nil
    ) {
      self.startPoint = startPoint
      self.endPoint = endPoint
      self.options = options
      self.units = units
      self.transform = transform
    }
  }

  case saveGState
  case restoreGState

  case pathSegment(PathSegment)
  case replacePathWithStrokePath

  case clip
  case clipWithRule(CGPathFillRule)
  case clipToRect(CGRect)
  case dash(DashPattern)
  case dashPhase(CGFloat)
  case dashLenghts([CGFloat])

  case fill
  case fillWithRule(CGPathFillRule)
  case fillEllipse(in: CGRect)
  case stroke
  case drawPath(mode: CGPathDrawingMode)
  case fillAndStroke

  case concatCTM(CGAffineTransform)

  case flatness(CGFloat)
  case lineWidth(CGFloat)
  case lineJoinStyle(CGLineJoin)
  case lineCapStyle(CGLineCap)
  case miterLimit(CGFloat)

  case colorRenderingIntent(CGColorRenderingIntent)
  case globalAlpha(CGFloat)
  case setGlobalAlphaToFillAlpha
  case fillColorSpace
  case strokeColorSpace
  case strokeColor(RGBCGColor)
  case strokeAlpha(CGFloat)
  case strokeNone
  case fillColor(RGBCGColor)
  case fillAlpha(CGFloat)
  case fillNone

  case fillRule(CGPathFillRule)

  case linearGradient(String, LinearGradientDrawingOptions)
  case radialGradient(String, RadialGradientDrawingOptions)
  case fillLinearGradient(String, LinearGradientDrawingOptions)
  case fillRadialGradient(String, RadialGradientDrawingOptions)
  case strokeLinearGradient(String, LinearGradientDrawingOptions)
  case strokeRadialGradient(String, RadialGradientDrawingOptions)
  case subrouteWithName(String)
  case shadow(Shadow)
  case blendMode(CGBlendMode)

  case beginTransparencyLayer
  case endTransparencyLayer

  case composite([DrawStep])

  public static let empty = DrawStep.composite([])
  public static func savingGState(_ steps: DrawStep...) -> DrawStep {
    .composite([.saveGState] + steps + [.restoreGState])
  }
}
