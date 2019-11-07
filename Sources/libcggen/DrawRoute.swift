// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

typealias RGBACGColor = RGBAColor<CGFloat>

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

enum DrawStep {
  typealias RadialGradientDrawingOptions = (
    startCenter: CGPoint,
    startRadius: CGFloat,
    endCenter: CGPoint,
    endRadius: CGFloat,
    options: CGGradientDrawingOptions
  )

  typealias LinearGradientDrawingOptions = (
    startPoint: CGPoint,
    endPoint: CGPoint,
    options: CGGradientDrawingOptions
  )

  case saveGState
  case restoreGState

  case moveTo(CGPoint)
  case curveTo(CGPoint, CGPoint, CGPoint)
  case lineTo(CGPoint)
  case appendRectangle(CGRect)
  case appendRoundedRect(CGRect, rx: CGFloat, ry: CGFloat)
  case closePath
  case endPath
  case replacePathWithStrokePath

  case lines([CGPoint])

  case clip(CGPathFillRule)
  case clipToRect(CGRect)
  case dash(DashPattern)

  case fill(CGPathFillRule)
  case fillEllipse(in: CGRect)
  case stroke
  case drawPath(mode: CGPathDrawingMode)
  case addEllipse(in: CGRect)

  case concatCTM(CGAffineTransform)

  case flatness(CGFloat)
  case lineWidth(CGFloat)
  case lineJoinStyle(CGLineJoin)
  case lineCapStyle(CGLineCap)

  case colorRenderingIntent(CGColorRenderingIntent)
  case globalAlpha(CGFloat)
  case fillColorSpace
  case strokeColorSpace
  case strokeColor(RGBACGColor)
  case fillColor(RGBACGColor)

  case linearGradient(String, LinearGradientDrawingOptions)
  case radialGradient(String, RadialGradientDrawingOptions)
  case subrouteWithName(String)
  case shadow(Shadow)
  case blendMode(CGBlendMode)

  case beginTransparencyLayer
  case endTransparencyLayer

  case composite([DrawStep])

  static let empty = DrawStep.composite([])
  static func savingGState(_ steps: DrawStep...) -> DrawStep {
    return .composite([.saveGState] + steps + [.restoreGState])
  }
}

struct DrawRoute {
  let boundingRect: CGRect
  let gradients: [String: Gradient]
  let subroutes: [String: DrawRoute]
  let steps: [DrawStep]
  init(
    boundingRect: CGRect,
    gradients: [String: Gradient],
    subroutes: [String: DrawRoute],
    steps: [DrawStep]
  ) {
    self.boundingRect = boundingRect
    self.gradients = gradients
    self.subroutes = subroutes
    self.steps = steps
  }
}
