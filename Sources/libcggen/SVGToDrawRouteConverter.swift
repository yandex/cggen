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
  var fillRule: SVG.FillRule = .evenodd
  var fillAlpha: SVG.Float = 1
  var fill: SVG.Paint = .rgb(.black())

  var currentFill: RGBAColorType<UInt8, SVG.Float>?

  mutating func updateCurrentFill() -> DrawStep {
    guard case let .rgb(color) = fill, currentFill != color.withAlpha(fillAlpha) else {
      return .empty
    }
    return .fillColor(color.norm().withAlpha(fillAlpha.cgfloat))
  }
}

private func drawstep(svg: SVG, ctx: Context) throws -> DrawStep {
  switch svg {
  case let .rect(r):
    let (steps, ctx) = apply(to: ctx, presentation: r.presentation)
    return .composite(steps + [
      .appendRectangle(.init(r)),
      .fill(.init(ctx.fillRule)),
    ])
  case .title, .desc:
    return .empty
  case let .group(g):
    let ctx = modified(ctx) {
      $0.fillRule ?= g.presentation.fillRule
    }
    var pre: [DrawStep] = [.saveGState]
    var post: [DrawStep] = []
    if let transform = g.transform {
      pre += transform.map(CGAffineTransform.init).map(DrawStep.concatCTM)
    }
    if let opacity = g.presentation.opacity {
      pre += [.globalAlpha(CGFloat(opacity)), .beginTransparencyLayer]
      post.append(.endTransparencyLayer)
    }
    post.append(.restoreGState)
    return try .composite(pre + g.children.map(drawstep(ctx: ctx)) + post)
  case .svg:
    fatalError()
  case let .polygon(p):
    guard let points = p.points else { return .empty }
    let (steps, ctx) = apply(to: ctx, presentation: p.presentation)
    let cgpoints = points.map {
      CGPoint(x: $0._1, y: $0._2)
    }
    return .composite(steps + [.polygon(cgpoints), .fill(.init(ctx.fillRule))])
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
  var ctx = modified(ctx) {
    $0.fillRule ?= presentation.fillRule
    $0.fillAlpha ?= presentation.fillOpacity
    $0.fill ?= presentation.fill
  }

  var steps = [DrawStep]()
  steps.append(ctx.updateCurrentFill())

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

extension CGAffineTransform {
  init(svgTransform: SVG.Transform) {
    switch svgTransform {
    case let .translate(tx: tx, ty: ty):
      self.init(translationX: CGFloat(tx), y: CGFloat(ty ?? 0))
    case let .scale(sx: sx, sy: sy):
      self.init(scaleX: CGFloat(sx), y: CGFloat(sy ?? sx))
    case let .rotate(angle: angle, anchor: nil):
      self.init(rotationAngle: CGFloat(angle))
    case let .rotate(angle: angle, anchor: anchor?):
      let cx = CGFloat(anchor.cx)
      let cy = CGFloat(anchor.cy)
      self = CGAffineTransform(translationX: cx, y: cy)
        .concatenating(.init(rotationAngle: CGFloat(angle)))
        .concatenating(.init(translationX: -cx, y: -cy))
    }
  }
}
