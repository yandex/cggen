import Foundation

public enum Command: UInt8 {
  // A: [T]                       = size: UInt32, A[0], A[1], ..., A[size-1]
  // (T, Y)                       = T, Y

  // CGFloat                      = Float32
  // CGSize                       = width: CGFloat, height: CGFloat
  // CGPoint                      = x: CGFloat, y: CGFloat
  // CGRect                       = x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
  // Bool                         = false   = 0 | true     = 1
  // CGPathFillRule               = winding = 0 | evenOdd  = 1
  // DashPattern                  = phase: CGFloat, lengths: [CGFloat]
  // CGPathDrawingMode            = fill = 0 | eoFill = 1 | stroke = 2 | fillStroke = 3 | eoFillStroke = 4
  // CGAffineTransform            = a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat
  // CGLineJoin                   = miter = 0 | round = 1 | bevel   = 2
  // CGLineCap                    = butt  = 0 | round = 1 | square  = 2
  // RGBACGColor                  = red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat
  // CGGradientDrawingOptions     = {} = 0 | {.drawsBeforeStartLocation} = 1 | {.drawsAfterEndLocation} = 2 | {.drawsBeforeStartLocation, .drawsAfterEndLocation} = 3
  // LinearGradientDrawingOptions = startPoint: CGPoint, endPoint: CGPoint, options: CGGradientDrawingOptions
  // RadialGradientDrawingOptions = startCenter: CGPoint, startRadius: CGFloat, endCenter: CGPoint, endRadius: CGFloat, options: CGGradientDrawingOptions
  // Gradient                     = locationAndColors: [(CGFloat, RGBACGColor)]
  // Shadow                       = offset: CGSize, blur: CGFloat, color: RGBACGColor
  // CGBlendMode                  = 0..27    (rawValue)
  case saveGState = 0
  case restoreGState

  case moveTo // (CGPoint)
  case curveTo // (CGPoint, CGPoint, CGPoint)
  case lineTo // (CGPoint)
  case appendRectangle // (CGRect)
  case appendRoundedRect // (CGRect, rx: CGFloat, ry: CGFloat)
  case addArc // (center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool)
  case closePath
  case replacePathWithStrokePath

  case lines // ([CGPoint])

  case clip
  case clipWithRule // (CGPathFillRule)
  case clipToRect // (CGRect)
  case dash // (DashPattern)

  case fill
  case fillWithRule // (CGPathFillRule)
  case fillEllipse // (in: CGRect)
  case stroke
  case drawPath // (mode: CGPathDrawingMode)
  case addEllipse // (in: CGRect)
  case fillAndStroke

  case concatCTM // (CGAffineTransform)

  case flatness // (CGFloat)
  case lineWidth // (CGFloat)
  case lineJoinStyle // (CGLineJoin)
  case lineCapStyle // (CGLineCap)

  case colorRenderingIntent // (CGColorRenderingIntent)
  case globalAlpha // (CGFloat)
  case strokeColor // (RGBACGColor)
  case fillColor // (RGBACGColor)
  case fillRule // (CGPathFillRule)

  case linearGradient // (id: UInt32, LinearGradientDrawingOptions)
  case radialGradient // (id: UInt32, RadialGradientDrawingOptions)
  case linearGradientInlined // (Gradient, LinearGradientDrawingOptions)
  case radialGradientInlined // (Gradient, RadialGradientDrawingOptions)
  case subrouteWithId // (id: UInt32)
  case shadow // (Shadow)
  case blendMode // (CGBlendMode)

  case beginTransparencyLayer
  case endTransparencyLayer
}
