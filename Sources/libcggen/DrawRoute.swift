// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

struct Gradient {
  enum Kind {
    case axial
    case radial(startRadius: CGFloat, endRadius: CGFloat)
  }

  let locationAndColors: [(CGFloat, RGBACGColor)]
  let startPoint: CGPoint
  let endPoint: CGPoint
  let options: CGGradientDrawingOptions
  let kind: Kind
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
  case saveGState
  case restoreGState

  case moveTo(CGPoint)
  case curveTo(CGPoint, CGPoint, CGPoint)
  case lineTo(CGPoint)
  case appendRectangle(CGRect)
  case closePath
  case endPath

  case clip(CGPathFillRule)
  case clipToRect(CGRect)
  case dash(DashPattern)

  case fill(CGPathFillRule)
  case stroke

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

  case paintWithGradient(String)
  case subrouteWithName(String)
  case blendMode(CGBlendMode)

  case beginTransparencyLayer
  case endTransparencyLayer

  case composite([DrawStep])

  static let empty = DrawStep.composite([])
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
