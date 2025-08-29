import CoreGraphics

/*
 A: [T]                       = size: UInt32, A[0], A[1], ..., A[size-1]
 (T, Y)                       = T, Y

 CGFloat                      = Float32
 CGSize                       = width: CGFloat, height: CGFloat
 CGPoint                      = x: CGFloat, y: CGFloat
 CGRect                       = x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
 Bool                         = false   = 0 | true     = 1
 CGPathFillRule               = winding = 0 | evenOdd  = 1
 DashPattern                  = phase: CGFloat, lengths: [CGFloat]
 CGPathDrawingMode            = fill = 0 | eoFill = 1 | stroke = 2 | fillStroke = 3 | eoFillStroke = 4
 CGAffineTransform            = a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat
 CGLineJoin                   = miter = 0 | round = 1 | bevel   = 2
 CGLineCap                    = butt  = 0 | round = 1 | square  = 2
 BCRGBAColor                  = red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat
 CGGradientDrawingOptions     = {} = 0 | {.drawsBeforeStartLocation} = 1 | {.drawsAfterEndLocation} = 2 | {.drawsBeforeStartLocation, .drawsAfterEndLocation} = 3
 LinearGradientDrawingOptions =
  startPoint: CGPoint,
  endPoint: CGPoint,
  options: CGGradientDrawingOptions
 RadialGradientDrawingOptions = startCenter: CGPoint, startRadius: CGFloat, endCenter: CGPoint, endRadius: CGFloat, options: CGGradientDrawingOptions
 Gradient                     = locationAndColors: [(CGFloat, BCRGBAColor)]
 Shadow                       = offset: CGSize, blur: CGFloat, color: BCRGBAColor
 CGBlendMode                  = 0..27    (rawValue)
 */
public enum DrawCommand: UInt8 {
  public typealias NoArgs = Void

  case saveGState = 0
  public typealias SaveGStateArgs = NoArgs

  case restoreGState
  public typealias RestoreGStateArgs = NoArgs

  case moveTo
  public typealias MoveToArgs = CGPoint

  case curveTo
  public typealias CurveToArgs = BCCubicCurve

  case quadCurveTo
  public typealias QuadCurveToArgs = BCQuadCurve

  case lineTo
  public typealias LineToArgs = CGPoint

  case appendRectangle
  public typealias AppendRectangleArgs = CGRect

  case appendRoundedRect
  public typealias AppendRoundedRectArgs = (CGRect, rx: CGFloat, ry: CGFloat)

  case addArc
  public typealias AddArcArgs = (
    center: CGPoint, radius: CGFloat,
    startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool
  )

  case closePath
  public typealias ClosePathArgs = NoArgs

  case replacePathWithStrokePath
  public typealias ReplacePathWithStrokePathArgs = NoArgs

  case lines
  public typealias LinesArgs = [CGPoint]

  case clip
  public typealias ClipArgs = NoArgs

  case clipWithRule
  public typealias ClipWithRuleArgs = BCFillRule

  case clipToRect
  public typealias ClipToRectArgs = CGRect

  case dash
  public typealias DashArgs = BCDashPattern

  case dashPhase
  public typealias DashPhaseArgs = CGFloat

  case dashLengths
  public typealias DashLengthsArgs = [CGFloat]

  case fill
  public typealias FillArgs = NoArgs

  case fillWithRule
  public typealias FillWithRuleArgs = BCFillRule

  case fillEllipse
  public typealias FillEllipseArgs = CGRect

  case stroke
  public typealias StrokeArgs = NoArgs

  case drawPath
  public typealias DrawPathArgs = CGPathDrawingMode

  case addEllipse
  public typealias AddEllipseArgs = CGRect

  case fillAndStroke
  public typealias FillAndStrokeArgs = NoArgs

  case setGlobalAlphaToFillAlpha
  public typealias SetGlobalAlphaToFillAlphaArgs = NoArgs

  case concatCTM
  public typealias ConcatCTMArgs = CGAffineTransform

  case flatness
  public typealias FlatnessArgs = CGFloat

  case lineWidth
  public typealias LineWidthArgs = CGFloat

  case lineJoinStyle
  public typealias LineJoinStyleArgs = CGLineJoin

  case lineCapStyle
  public typealias LineCapStyleArgs = CGLineCap

  case colorRenderingIntent
  public typealias ColorRenderingIntentArgs = CGColorRenderingIntent

  case globalAlpha
  public typealias GlobalAlphaArgs = CGFloat

  case strokeColor
  public typealias StrokeColorArgs = BCRGBColor

  case strokeAlpha
  public typealias StrokeAlphaArgs = CGFloat

  case strokeNone
  public typealias StrokeNoneArgs = NoArgs

  case fillColor
  public typealias FillColorArgs = BCRGBColor

  case fillAlpha
  public typealias FillAlphaArgs = CGFloat

  case fillNone
  public typealias FillNoneArgs = NoArgs

  case fillRule
  public typealias FillRuleArgs = BCFillRule

  case linearGradient
  public typealias LinearGradientArgs = (
    id: UInt32, BCLinearGradientDrawingOptions
  )

  case radialGradient
  public typealias RadialGradientArgs = (
    id: UInt32, BCRadialGradientDrawingOptions
  )

  case fillLinearGradient
  public typealias FillLinearGradientArgs = (
    id: UInt32, BCLinearGradientDrawingOptions
  )

  case fillRadialGradient
  public typealias FillRadialGradientArgs = (
    id: UInt32, BCRadialGradientDrawingOptions
  )

  case strokeLinearGradient
  public typealias StrokeLinearGradientArgs = (
    id: UInt32, BCLinearGradientDrawingOptions
  )

  case strokeRadialGradient
  public typealias StrokeRadialGradientArgs = (
    id: UInt32, BCRadialGradientDrawingOptions
  )

  case subrouteWithId
  public typealias SubrouteWithIdArgs = UInt32

  case shadow
  public typealias ShadowArgs = BCShadow

  case blendMode
  public typealias BlendModeArgs = CGBlendMode

  case beginTransparencyLayer
  public typealias BeginTransparencyLayerArgs = NoArgs

  case endTransparencyLayer
  public typealias EndTransparencyLayerArgs = NoArgs

  case miterLimit
  public typealias MiterLimitArgs = CGFloat
}

public enum PathCommand: UInt8 {
  public typealias NoArgs = Void

  case moveTo = 0
  public typealias MoveToArgs = CGPoint

  case curveTo
  public typealias CurveToArgs = BCCubicCurve

  case quadCurveTo
  public typealias QuadCurveToArgs = BCQuadCurve

  case lineTo
  public typealias LineToArgs = CGPoint

  case appendRectangle
  public typealias AppendRectangleArgs = CGRect

  case appendRoundedRect
  public typealias AppendRoundedRectArgs = (CGRect, rx: CGFloat, ry: CGFloat)

  case addArc
  public typealias AddArcArgs = (
    center: CGPoint, radius: CGFloat,
    startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool
  )

  case closePath
  public typealias ClosePathArgs = NoArgs

  case lines
  public typealias LinesArgs = [CGPoint]

  case addEllipse
  public typealias AddEllipseArgs = CGRect
}

extension DrawCommand {
  public init(_ pathCommand: PathCommand) {
    switch pathCommand {
    case .moveTo: self = .moveTo
    case .curveTo: self = .curveTo
    case .quadCurveTo: self = .quadCurveTo
    case .lineTo: self = .lineTo
    case .appendRectangle: self = .appendRectangle
    case .appendRoundedRect: self = .appendRoundedRect
    case .addArc: self = .addArc
    case .closePath: self = .closePath
    case .lines: self = .lines
    case .addEllipse: self = .addEllipse
    }
  }
}
