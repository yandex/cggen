@preconcurrency import CoreGraphics
import Foundation

import Base

typealias RGBACGColor = RGBAColor<CGFloat>
typealias RGBCGColor = RGBColor<CGFloat>

struct Gradient {
  var locationAndColors: [(CGFloat, RGBACGColor)]
}

struct Shadow {
  var offset: CGSize
  var blur: CGFloat
  var color: RGBACGColor
}

struct DashPattern {
  let phase: CGFloat
  let lengths: [CGFloat]
  init(phase: CGFloat, lengths: [CGFloat]) {
    self.phase = phase
    self.lengths = lengths
  }
}

enum DrawStep: Sendable {
  struct RadialGradientDrawingOptions {
    var startCenter: CGPoint
    var startRadius: CGFloat
    var endCenter: CGPoint
    var endRadius: CGFloat
    var options: CGGradientDrawingOptions
    var transform: CGAffineTransform?
  }

  public enum Units {
    case userSpaceOnUse, objectBoundingBox
  }

  struct LinearGradientDrawingOptions {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var options: CGGradientDrawingOptions
    var units: Units
    var transform: CGAffineTransform?
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

  static let empty = DrawStep.composite([])
  static func savingGState(_ steps: DrawStep...) -> DrawStep {
    .composite([.saveGState] + steps + [.restoreGState])
  }
}

public enum PathSegment: Sendable {
  case moveTo(CGPoint)
  case curveTo(CGPoint, CGPoint, CGPoint)
  case lineTo(CGPoint)
  case appendRectangle(CGRect)
  case appendRoundedRect(CGRect, rx: CGFloat, ry: CGFloat)
  case addEllipse(in: CGRect)
  case addArc(
    center: CGPoint,
    radius: CGFloat,
    startAngle: CGFloat,
    endAngle: CGFloat,
    clockwise: Bool
  )
  case closePath
  case endPath

  case lines([CGPoint])
  case composite([PathSegment])

  public static let empty: PathSegment = .composite([])
}

struct DrawRoutine: Sendable {
  var boundingRect: CGRect
  var gradients: [String: Gradient]
  var subroutines: [String: DrawRoutine]
  var steps: [DrawStep]

  init(
    boundingRect: CGRect,
    gradients: [String: Gradient],
    subroutines: [String: DrawRoutine],
    steps: [DrawStep]
  ) {
    self.boundingRect = boundingRect
    self.gradients = gradients
    self.subroutines = subroutines
    self.steps = steps
  }
}

struct PathRoutine {
  var id: String
  var content: [PathSegment]
}

struct Routines: Sendable {
  var drawRoutine: DrawRoutine
  var pathRoutines: [PathRoutine]

  init(drawRoutine: DrawRoutine, pathRoutines: [PathRoutine] = []) {
    self.drawRoutine = drawRoutine
    self.pathRoutines = pathRoutines
  }
}
