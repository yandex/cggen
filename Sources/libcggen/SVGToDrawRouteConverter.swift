import Base
import CoreGraphics

enum SVGToDrawRouteConverter {
  static func convert(document: SVG.Document) throws -> DrawRoute {
    let boundingRect = document.boundingRect
    let height = boundingRect.size.height
    let gradients = try Dictionary(
      uniqueKeysWithValues: document.children.flatMap(gradients(svg:))
    )
    return try .init(
      boundingRect: boundingRect,
      gradients: gradients.mapValues { $0.0 },
      subroutes: [:],
      steps: [.concatCTM(.invertYAxis(height: height))] +
        document.children.map(drawstep(ctx: .init(
          drawingSize: boundingRect.size,
          gradients: gradients.mapValues { $0.1 }
        )))
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
  case noStopColor
  case noStopOffset
  case gradientNotFound(String)
}

private struct Context {
  var fillRule: SVG.FillRule = .evenodd
  var fillAlpha: SVG.Float = 1
  var fill: SVG.Paint = .rgb(.black())

  var currentFill: RGBAColorType<UInt8, SVG.Float>?
  var drawingSize: CGSize
  let gradients: [String: SVG.LinearGradient]

  init(drawingSize: CGSize, gradients: [String: SVG.LinearGradient]) {
    self.drawingSize = drawingSize
    self.gradients = gradients
  }

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
    var post = [DrawStep]()
    if case let .funciri(grad) = ctx.fill {
      let g = try ctx.gradients[grad] !! Err.gradientNotFound(grad)
      post.append(.paintWithGradient(
        grad,
        start: g.startPoint(in: ctx.drawingSize),
        end: g.endPoint(in: ctx.drawingSize))
      )
    }
    return .composite(steps + [
      .appendRectangle(.init(r)),
      .fill(.init(ctx.fillRule)),
    ] + post)
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
  case .linearGradient:
    fatalError()
  case .mask:
    fatalError()
  case .use:
    fatalError()
  case .defs:
    return .empty
  }
}

private func gradients(svg: SVG) throws -> [(String, (Gradient, SVG.LinearGradient))] {
  switch svg {
  case let .defs(defs):
    return try defs.children.flatMap(gradients(svg:))
  case let .linearGradient(g):
    guard let id = g.core.id,
      let startPoint = zip(g.x1, g.y1).map({ CGPoint(x: $0.0.number, y: $0.1.number) }),
      let endPoint = zip(g.x2, g.y2).map({ CGPoint(x: $0.0.number, y: $0.1.number) })
    else { return [] }
    let stops = g.stops
    let locandcolors: [(CGFloat, RGBACGColor)] = try stops.map {
      let color = try $0.presentation.stopColor !! Err.noStopColor
      let opacity = CGFloat($0.presentation.stopOpacity ?? 1)
      let offset: CGFloat
      switch try $0.offset !! Err.noStopOffset {
      case let .number(num):
        offset = CGFloat(num)
      case let .percentage(percentage):
        offset = CGFloat(percentage) / 100
      }
      return (offset, color.norm().withAlpha(opacity))
    }
    return [
      (id, (Gradient(
        locationAndColors: locandcolors,
        startPoint: startPoint,
        endPoint: endPoint, options: [], kind: .axial
      ), g)),
    ]
  default:
    return []
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

extension SVG.LinearGradient {
  func startPoint(in drawingSize: CGSize) -> CGPoint? {
    return zip(x1, y1).map { abs($0.0, $0.1, drawingSize) }
  }

  func endPoint(in drawingSize: CGSize) -> CGPoint? {
    return zip(x2, y2).map { abs($0.0, $0.1, drawingSize) }
  }
}

private func abs(
  _ x: SVG.Coordinate,
  _ y: SVG.Coordinate,
  _ size: CGSize
) -> CGPoint {
  return .init(x: x.abs(in: size.width), y: y.abs(in: size.height))
}

extension SVG.Coordinate {
  func abs(in value: CGFloat) -> CGFloat {
    switch unit {
    case nil, .pt?, .px?:
      return value
    case .percent?:
      return CGFloat(number / 100) * value
    }
  }
}
