// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation
import Base

public struct Gradient {
  public let locationAndColors: [(CGFloat, RGBAColor)]
  public let startPoint: CGPoint
  public let endPoint: CGPoint
  public let options: CGGradientDrawingOptions
}

public struct DashPattern {
  public let phase: CGFloat
  public let lengths: [CGFloat]
  public init(phase: CGFloat, lengths: [CGFloat]) {
    self.phase = phase
    self.lengths = lengths
  }
}

public enum DrawStep {
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
  case strokeColor(RGBAColor)
  case fillColor(RGBAColor)

  case paintWithGradient(String)
  case subrouteWithName(String)

  case beginTransparencyLayer
  case endTransparencyLayer

  case composite([DrawStep])

  static let empty = DrawStep.composite([])
}

public struct DrawRoute {
  public let boundingRect: CGRect
  public let gradients: [String: Gradient]
  public let subroutes: [String: DrawRoute]
  public let steps: [DrawStep]
  public init(boundingRect: CGRect,
              gradients: [String: Gradient],
              subroutes: [String: DrawRoute],
              steps: [DrawStep]) {
    self.boundingRect = boundingRect
    self.gradients = gradients
    self.subroutes = subroutes
    self.steps = steps
  }
}
