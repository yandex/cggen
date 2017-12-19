// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct RGBAColor {
  let red: CGFloat
  let green: CGFloat
  let blue: CGFloat
  let alpha: CGFloat
  var cgColor: CGColor {
    return CGColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  static func rgb(_ rgb: RGBColor, alpha: CGFloat) -> RGBAColor {
    return RGBAColor(red: rgb.red, green: rgb.green,
                     blue: rgb.blue, alpha: alpha)
  }
}

struct RGBColor {
  let red: CGFloat
  let green: CGFloat
  let blue: CGFloat
}

struct Gradient {
  let locationAndColors: [(CGFloat, RGBAColor)]
  let startPoint: CGPoint
  let endPoint: CGPoint
  let options: CGGradientDrawingOptions
}

struct DashPattern {
  let phase: CGFloat
  let lengths: [CGFloat]
}

enum DrawStep {
  case saveGState
  case restoreGState
  case moveTo(CGPoint)
  case curve(CGPoint, CGPoint, CGPoint)
  case line(CGPoint)
  case closePath
  case clip(CGPathFillRule)
  case dash(DashPattern)
  case endPath
  case flatness(CGFloat)
  case fillColorSpace
  case strokeColorSpace
  case appendRectangle(CGRect)
  case fill(RGBAColor, CGPathFillRule)
  case concatCTM(CGAffineTransform)
  case lineWidth(CGFloat)
  case stroke(RGBAColor)
  case colorRenderingIntent
  case parametersFromGraphicsState
  case paintWithGradient(String)
  case subroute(DrawRoute)
}

struct DrawRoute {
  let boundingRect: CGRect
  let gradients: [String: Gradient]
  private(set) var steps: Array<DrawStep> = []
  init(boundingRect: CGRect, gradients: [String: Gradient]) {
    self.boundingRect = boundingRect
    self.gradients = gradients
  }

  public mutating func push(step: DrawStep) -> Int {
    steps.append(step)
    return steps.count
  }
}

extension DrawRoute {
  func draw(scale: CGFloat) -> CGImage {
    let ctx = CGContext(data: nil,
                        width: Int(boundingRect.width * scale),
                        height: Int(boundingRect.height * scale),
                        bitsPerComponent: 8,
                        bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: scale, y: scale)
    draw(on: ctx)
    return ctx.makeImage()!
  }

  private func draw(on ctx: CGContext) {
    for step in steps {
      switch step {
      case .saveGState:
        ctx.saveGState()
      case .restoreGState:
        ctx.restoreGState()
      case let .moveTo(p):
        ctx.move(to: p)
      case let .curve(p1, p2, p3):
        ctx.addCurve(to: p3, control1: p1, control2: p2)
      case let .line(p):
        ctx.addLine(to: p)
      case .closePath:
        ctx.closePath()
      case let .clip(rule):
        ctx.clip(using: rule)
      case .endPath:
        // FIXME: Decide what to do here
        break
      case let .flatness(flatness):
        ctx.setFlatness(flatness)
      case .fillColorSpace:
        // FIXME: Color space
        break
      case let .appendRectangle(rect):
        ctx.addRect(rect)
      case let .fill(color, rule):
        ctx.setFillColor(color.cgColor)
        ctx.fillPath(using: rule)
      case .strokeColorSpace:
        // FIXME: Color space
        break
      case let .concatCTM(transform):
        ctx.concatenate(transform)
      case let .lineWidth(w):
        ctx.setLineWidth(w)
      case let .stroke(color):
        ctx.setStrokeColor(color.cgColor)
        ctx.strokePath()
      case .colorRenderingIntent:
        break
      case .parametersFromGraphicsState:
        break
      case let .paintWithGradient(gradientKey):
        let grad = gradients[gradientKey]!
        let locs = grad.locationAndColors.map { $0.0 }
        let color = grad.locationAndColors.map { $0.1.cgColor }
        let cgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                colors: color as CFArray,
                                locations: locs)!
        ctx.drawLinearGradient(cgGrad,
                               start: grad.startPoint,
                               end: grad.endPoint,
                               options: grad.options)
      case let .dash(pattern):
        ctx.setLineDash(phase: pattern.phase, lengths: pattern.lengths)
      case let .subroute(route):
        route.draw(on: ctx)
      }
    }
  }
}
