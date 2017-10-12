//
//  DrawRoute.swift
//  cggenPackageDescription
//
//  Created by Alfred Zien on 12/10/2017.
//

import Foundation

enum DrawStep {
  case saveGState
  case restoreGState
  case moveTo(CGPoint)
  case curve(CGPoint, CGPoint, CGPoint)
  case line(CGPoint)
  case closePath
  case clip(CGPathFillRule)
  case endPath
  case flatness(CGFloat)
  case nonStrokeColorSpace(CGColorSpace)
  case nonStrokeColor(CGColor)
  case appendRectangle(CGRect)
  case fill(CGPathFillRule)
}

class DrawRoute {
  let boundingRect : CGRect;
  private var steps : Array<DrawStep> = [];
  init(boundingRect : CGRect) {
    self.boundingRect = boundingRect
  }
  public func push(step: DrawStep) -> Int {
    steps.append(step)
    return steps.count
  }
  public func getSteps() -> [DrawStep] {
    return steps
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
    for step in steps {
      switch step {
      case .saveGState:
        ctx.saveGState()
      case .restoreGState:
        ctx.restoreGState()
      case .moveTo(let p):
        ctx.move(to: p)
      case .curve(let p1, let p2, let p3):
        ctx.addCurve(to: p3, control1: p1, control2: p2)
      case .line(let p):
        ctx.addLine(to: p)
      case .closePath:
        ctx.closePath()
      case .clip(let rule):
        ctx.clip(using: rule)
      case .endPath:
        break
//        ctx.closePath()
      case .flatness(let flatness):
        ctx.setFlatness(flatness)
      case .nonStrokeColorSpace(let cs):
        ctx.setFillColorSpace(cs)
      case .nonStrokeColor(let color):
        ctx.setFillColor(color)
      case .appendRectangle(let rect):
        ctx.addRect(rect)
      case .fill(let rule):
        ctx.fillPath(using: rule)
      }
    }
    return ctx.makeImage()!
  }
}
