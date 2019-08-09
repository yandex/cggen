import Base
import CoreGraphics

enum SVGToDrawRouteConverter {
  static func convert(document: SVG.Document) throws -> DrawRoute {
    let boundingRect = document.boundingRect
    let height = boundingRect.size.height
    return try .init(
      boundingRect: boundingRect,
      gradients: [:],
      subroutes: [:],
      steps: [.concatCTM(.invertYAxis(height: height))] +
        document.children.map(drawstep(ctx: .default))
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
    let (steps, ctx) = apply(to: ctx, presentation: r.presentation)
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
  case let .polygon(p):
    guard let points = p.points, points.count.isMultiple(of: 2) else {
      return .empty
    }
    let (steps, ctx) = apply(to: ctx, presentation: p.presentation)
    let cgpoints = points.splitBy(subSize: 2).map {
      CGPoint(x: $0.first!, y: $0.last!)
    }
    return .composite(steps + [.polygon(cgpoints), .fill(ctx.fillRule)])
  case .mask:
    fatalError()
  case .use:
    fatalError()
  case .defs:
    fatalError()
  }
}

private func apply(
  to ctx: Context,
  presentation: SVG.PresentationAttributes
) -> ([DrawStep], Context) {
  let ctx = modified(ctx) {
    $0.fillRule ?= presentation.fillRule.map(CGPathFillRule.init)
  }
  var steps = [DrawStep]()
  if let fillColor = presentation.fill {
    switch fillColor {
    case .currentColor:
      break
    case .none:
      steps.append(.fillColor(.init(gray: 0, alpha: 0)))
    case let .rgb(color):
      steps.append(.fillColor(color.norm().withAlpha(ctx.fillAlpha)))
    }
  }
  return (steps, ctx)
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

extension RGBACGColor {
  static let none = RGBACGColor(red: .zero, green: .zero, blue: .zero, alpha: .zero)
}
