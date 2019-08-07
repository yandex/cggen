import Base
import CoreGraphics

enum SVGToDrawRouteConverter {
  static func convert(document: SVG.Document) throws -> DrawRoute {
    return try .init(
      boundingRect: document.boundingRect,
      gradients: [:],
      subroutes: [:],
      steps: document.children.map(drawstep(ctx: .default))
    )
  }
}

extension SVG.Document {
  var boundingRect: CGRect {
    return CGRect(
      x: 0.0, y: 0.0,
      width: width?.number ?? 0,
      height: width?.number ?? 0
    )
  }
}

private enum Err: Swift.Error {
  case widthLessThan0(SVG.Rect)
  case heightLessThan0(SVG.Rect)
}

private struct Context {
  static let `default` = Context()
  var fillRule: CGPathFillRule = .evenOdd
  var fillAlpha: CGFloat = 1
}

private func drawstep(svg: SVG, ctx: Context) throws -> DrawStep {
  switch svg {
  case let .rect(r):
    let ctx = modified(ctx) {
      $0.fillRule ?= r.presentation.fillRule.map(CGPathFillRule.init)
    }
    var steps = [DrawStep]()
    if let fillColor = r.presentation.fill {
      switch fillColor {
      case .currentColor:
        break
      case .none:
        steps.append(.fillColor(.rgb(.black, alpha: 0)))
      case let .rgb(color):
        steps.append(.fillColor(.rgb(color, alpha: ctx.fillAlpha)))
      }
    }
    return .composite(steps + [
      .appendRectangle(.init(r)),
      .fill(ctx.fillRule),
    ])
  case .title, .desc:
    return .empty
  case let .group(g):
    let ctx = modified(ctx) {
      $0.fillRule ?= g.presentation.fillRule.map(CGPathFillRule.init)
    }
    return try .composite(g.children.map(drawstep(ctx: ctx)))
  case .svg:
    fatalError()
  case .polygon:
    fatalError()
  case .mask:
    fatalError()
  case .use:
    fatalError()
  case .defs:
    fatalError()
  }
}

private func drawstep(ctx: Context) -> (SVG) throws -> DrawStep {
  return { try drawstep(svg: $0, ctx: ctx) }
}

extension CGRect {
  init(_ r: SVG.Rect) {
    let cg: (KeyPath<SVG.Rect, SVG.Coordinate?>) -> CGFloat = {
      CGFloat(r[keyPath: $0]?.number ?? 0)
    }
    self.init(x: cg(\.x), y: cg(\.y), width: cg(\.width), height: cg(\.height))
  }
}

extension CGPathFillRule {
  init(_ r: SVG.FillRule) {
    switch r {
    case .evenodd:
      self = .evenOdd
    case .nonzero:
      self = .winding
    }
  }
}

extension RGBAColor {
  static let none = RGBAColor.rgb(.black, alpha: 0)
}
