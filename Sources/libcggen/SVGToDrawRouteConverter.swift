import Base
import CoreGraphics

enum SVGToDrawRouteConverter {
  static func convert(document: SVG.Document) throws -> DrawRoute {
    let boundingRect = document.boundingRect
    let height = boundingRect.size.height
    let gradients = try Dictionary(
      uniqueKeysWithValues: document.children.flatMap(gradients(svg:))
    )
    var context = Context(
      drawingArea: boundingRect,
      gradients: gradients.mapValues { $0.1 }
    )
    return try .init(
      boundingRect: boundingRect,
      gradients: gradients.mapValues { $0.0 },
      subroutes: [:],
      steps: [.concatCTM(.invertYAxis(height: height))] +
        document.children.map { try drawstep(svg: $0, ctx: &context)
        }
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
  private(set) var fillRule: SVG.FillRule = .evenodd
  private(set) var fillAlpha: SVG.Float = 1
  private(set) var fill: SVG.Paint = .rgb(.black())
  private(set) var strokeAlpha: SVG.Float = 1
  private(set) var stroke: SVG.Paint = .rgb(.black())
  private(set) var strokeWidth: SVG.Length = 1
  private(set) var strokeDashArray: [SVG.Length] = []
  private(set) var strokeDashOffset: SVG.Length = 0

  var currentFill: RGBAColorType<UInt8, SVG.Float>?
  var currentStroke: RGBAColorType<UInt8, SVG.Float>?
  var drawingArea: CGRect
  let gradients: [String: GradientStepsProvider]

  init(drawingArea: CGRect, gradients: [String: GradientStepsProvider]) {
    self.drawingArea = drawingArea
    self.gradients = gradients
  }

  mutating func updateCurrentFillAndStroke() -> DrawStep {
    func color(
      paint: SVG.Paint,
      opacity: SVG.Float,
      current: inout RGBAColorType<UInt8, SVG.Float>?,
      additionalCondition: Bool = true
    ) -> RGBACGColor? {
      guard case let .rgb(color) = paint,
        case let new = color.withAlpha(opacity),
        current != new, additionalCondition else {
        return nil
      }
      current = new
      return color.norm().withAlpha(opacity.cgfloat)
    }
    return .composite([
      color(paint: fill, opacity: fillAlpha, current: &currentFill).map(DrawStep.fillColor),
      color(paint: stroke, opacity: strokeAlpha, current: &currentStroke).map(DrawStep.strokeColor),
    ].compactMap(identity))
  }

  mutating func apply(
    _ presentation: SVG.PresentationAttributes,
    area: CGRect?
  ) -> DrawStep {
    fillRule ?= presentation.fillRule
    fillAlpha ?= presentation.fillOpacity
    fill ?= presentation.fill
    stroke ?= presentation.stroke
    strokeAlpha ?= presentation.strokeOpacity
    strokeWidth ?= presentation.strokeWidth
    strokeDashArray ?= presentation.strokeDashArray
    strokeDashOffset ?= presentation.strokeDashOffset
    drawingArea ?= area

    let strokeWidth = presentation.strokeWidth.map { (l) -> DrawStep in
      precondition(l.unit != .percent)
      return DrawStep.lineWidth(CGFloat(l.number))
    }
    let strokeLineCap = presentation.strokeLineCap.map {
      DrawStep.lineCapStyle(.init(svgCap: $0))
    }
    let strokeLineJoin = presentation.strokeLineJoin.map {
      DrawStep.lineJoinStyle(.init(svgJoin: $0))
    }
    let needsDashUpdate = presentation.strokeDashOffset != nil ||
      presentation.strokeDashArray != nil
    let strokeDash = needsDashUpdate ? currentDash.map(DrawStep.dash) : nil

    return .composite([
      strokeWidth,
      strokeLineCap,
      strokeLineJoin,
      strokeDash,
      updateCurrentFillAndStroke(),
    ].compactMap(identity))
  }

  func gradient(for paint: KeyPath<Context, SVG.Paint>) throws -> DrawStep? {
    if case let .funciri(grad) = self[keyPath: paint] {
      let g = try gradients[grad] !! Err.gradientNotFound(grad)
      return g(drawingArea)
    }
    return nil
  }

  func drawPath(path: DrawStep) throws -> DrawStep {
    return try .composite([
      gradient(for: \.fill).map {
        DrawStep.savingGState(
          path,
          DrawStep.clip(.init(fillRule)),
          $0
        )
      },
      currentDrawingMode.map(DrawStep.drawPath).map {
        DrawStep.composite([
          path,
          $0,
        ])
      },
      gradient(for: \.stroke).map {
        DrawStep.savingGState(
          path,
          DrawStep.replacePathWithStrokePath,
          DrawStep.clip(.init(fillRule)),
          $0
        )
      },
    ].compactMap(identity))
  }

  var currentDrawingMode: CGPathDrawingMode? {
    switch (currentStroke, currentFill, fillRule) {
    case (nil, nil, _):
      return nil
    case (nil, .some, .nonzero):
      return .fill
    case (nil, .some, .evenodd):
      return .eoFill
    case (.some, nil, _):
      return .stroke
    case (.some, .some, .nonzero):
      return .fillStroke
    case (.some, .some, .evenodd):
      return .eoFillStroke
    }
  }

  var currentDash: DashPattern? {
    let lengths = strokeDashArray.map {
      CGFloat($0.number)
    }
    let phase = CGFloat(strokeDashOffset.number)
    switch strokeDashArray.count {
    case 0:
      return nil
    case let even where even.isMultiple(of: 2):
      return .init(phase: phase, lengths: lengths)
    default:
      return .init(phase: phase, lengths: lengths + lengths)
    }
  }
}

private func drawShape(
  pathConstruction: DrawStep,
  presentation: SVG.PresentationAttributes,
  area: CGRect,
  ctx: Context
) throws -> DrawStep {
  var ctx = ctx
  let strokeAndFill = ctx.apply(presentation, area: area)
  return try .composite([
    .saveGState,
    strokeAndFill,
    ctx.drawPath(path: pathConstruction),
    .restoreGState,
  ])
}

private func drawstep(svg: SVG, ctx: inout Context) throws -> DrawStep {
  switch svg {
  case let .rect(r):
    let rect = CGRect(r)
    let pathConstruction: DrawStep
    switch (r.rx.map { CGFloat($0.number) }, r.ry.map { CGFloat($0.number) }) {
    case (nil, nil):
      pathConstruction = .appendRectangle(rect)
    case let (rx?, nil):
      pathConstruction = .appendRoundedRect(rect, rx: rx, ry: rx)
    case let (nil, ry?):
      pathConstruction = .appendRoundedRect(rect, rx: ry, ry: ry)
    case let (rx?, ry?):
      pathConstruction = .appendRoundedRect(rect, rx: rx, ry: ry)
    }
    return try drawShape(
      pathConstruction: pathConstruction,
      presentation: r.presentation,
      area: rect,
      ctx: ctx
    )
  case .title, .desc:
    return .empty
  case let .group(g):
    let presentationSteps = ctx.apply(g.presentation, area: nil)
    var pre: [DrawStep] = [.saveGState, presentationSteps]
    var post: [DrawStep] = []
    if let transform = g.transform {
      pre += transform.map(CGAffineTransform.init).map(DrawStep.concatCTM)
    }
    if let opacity = g.presentation.opacity {
      pre += [.globalAlpha(CGFloat(opacity)), .beginTransparencyLayer]
      post.append(.endTransparencyLayer)
    }
    post.append(.restoreGState)
    var childContext = ctx
    return try .composite(pre + g.children.map { try drawstep(svg: $0, ctx: &childContext) } + post)
  case .svg:
    fatalError()
  case let .polygon(p):
    guard let points = p.points else { return .empty }
    let cgpoints = points.map {
      CGPoint(x: $0._1, y: $0._2)
    }
    let box: CGRect = CGPath.make {
      $0.addLines(between: cgpoints)
      $0.closeSubpath()
    }.boundingBox

    return try drawShape(
      pathConstruction: .composite([.lines(cgpoints), .closePath]),
      presentation: p.presentation,
      area: box,
      ctx: ctx
    )
  case .linearGradient, .radialGradient:
    fatalError()
  case .mask:
    fatalError()
  case .use:
    fatalError()
  case .defs:
    return .empty
  case let .circle(circle):
    guard let cx = circle.cx, let cy = circle.cy, let r = circle.r else { return .empty }
    let rect = CGRect.square(
      center: CGPoint(x: cx.number.cgfloat, y: cy.number.cgfloat),
      size: r.number.cgfloat * 2
    )
    return try drawShape(
      pathConstruction: .addEllipse(in: rect),
      presentation: circle.presentation,
      area: rect,
      ctx: ctx
    )
  case let .path(p):
    guard let commands = p.d else { return .empty }
    let cgpath = CGMutablePath()
    let path: [DrawStep] = commands.flatMap { (command) -> [DrawStep] in
      guard let move = command.moveTo.last else { return [DrawStep.empty] }
      let point = CGPoint(svgPair: move.coordinatePair)
      cgpath.move(to: point)
      return [DrawStep.moveTo(point)] + command.drawTo.map {
        switch $0 {
        case .closepath:
          cgpath.closeSubpath()
          return .closePath
        case let .lineto(_, pair):
          let point = CGPoint(svgPair: pair)
          cgpath.addLine(to: point)
          return .lineTo(point)
        case let .curveto(_, cp1, cp2, to):
          let cp1 = CGPoint(svgPair: cp1)
          let cp2 = CGPoint(svgPair: cp2)
          let to = CGPoint(svgPair: to)
          return .curveTo(cp1, cp2, to)
        case .smoothCurveto, .horizontalLineto, .quadraticBezierCurveto,
             .smoothQuadraticBezierCurveto, .verticalLineto:
          fatalError()
        }
      }
    }
    return try drawShape(
      pathConstruction: .composite(path),
      presentation: p.presentation,
      area: cgpath.boundingBox,
      ctx: ctx
    )
  case let .ellipse(ellipse):
    guard let cx = ellipse.cx, let cy = ellipse.cy,
      let rx = ellipse.rx, let ry = ellipse.ry,
      rx.number != 0, ry.number != 0 else { return .empty }
    let rect = CGRect(
      center: CGPoint(x: cx.number.cgfloat, y: cy.number.cgfloat),
      width: rx.number.cgfloat * 2,
      height: ry.number.cgfloat * 2
    )
    return try drawShape(
      pathConstruction: .addEllipse(in: rect),
      presentation: ellipse.presentation,
      area: rect,
      ctx: ctx
    )
  }
}

typealias GradientStepsProvider = (CGRect) -> DrawStep

private func gradients(svg: SVG) throws -> [(String, (Gradient, GradientStepsProvider))] {
  switch svg {
  case let .defs(defs):
    return try defs.children.flatMap(gradients(svg:))
  case let .linearGradient(g):
    guard let id = g.core.id else { return [] }
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
    let steps: GradientStepsProvider = { drawingrect in
      .linearGradient(id, (
        startPoint: g.startPoint(in: drawingrect),
        endPoint: g.endPoint(in: drawingrect),
        options: g.options
      ))
    }
    return [
      (id, (Gradient(locationAndColors: locandcolors), steps)),
    ]
  case let .radialGradient(g):
    guard let id = g.core.id else { return [] }
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
    let steps: GradientStepsProvider = { drawingrect in
      DrawStep.radialGradient(id, (
        startCenter: g.startCenter(in: drawingrect),
        startRadius: 0,
        endCenter: g.endCenter(in: drawingrect),
        endRadius: g.endRadius(in: drawingrect),
        options: g.options
      ))
    }
    return [
      (id, (Gradient(locationAndColors: locandcolors), steps)),
    ]
  default:
    return []
  }
}

extension CGPoint {
  init(svgPair: SVG.CoordinatePair) {
    self.init(x: svgPair._1, y: svgPair._2)
  }
}

extension CGLineCap {
  init(svgCap: SVG.LineCap) {
    switch svgCap {
    case .butt:
      self = .butt
    case .round:
      self = .round
    case .square:
      self = .square
    }
  }
}

extension CGLineJoin {
  init(svgJoin: SVG.LineJoin) {
    switch svgJoin {
    case .bevel:
      self = .bevel
    case .miter:
      self = .miter
    case .round:
      self = .round
    }
  }
}

extension CGRect {
  init(_ r: SVG.Rect) {
    let cg: (KeyPath<SVG.Rect, SVG.Coordinate?>) -> CGFloat = {
      CGFloat(r[keyPath: $0]?.number ?? 0)
    }
    self.init(x: cg(\.x), y: cg(\.y), width: cg(\.width), height: cg(\.height))
  }

  init(center: CGPoint, width: CGFloat, height: CGFloat) {
    self.init(
      x: center.x - width / 2,
      y: center.y - height / 2,
      width: width,
      height: height
    )
  }

  static func square(center: CGPoint, size: CGFloat) -> CGRect {
    return CGRect(center: center, width: size, height: size)
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
  func startPoint(in drawingArea: CGRect) -> CGPoint {
    return abs(x1 ?? 0%, y1 ?? 0%, drawingArea)
  }

  func endPoint(in drawingArea: CGRect) -> CGPoint {
    return abs(x2 ?? 100%, y2 ?? 0%, drawingArea)
  }

  var options: CGGradientDrawingOptions {
    return [.drawsAfterEndLocation, .drawsBeforeStartLocation]
  }
}

extension SVG.RadialGradient {
  private var cxWithDefault: SVG.Coordinate { return cx ?? 50% }
  private var cyWithDefault: SVG.Coordinate { return cy ?? 50% }

  func startCenter(in drawingAres: CGRect) -> CGPoint {
    return abs(fx ?? cxWithDefault, fy ?? cyWithDefault, drawingAres)
  }

  func endCenter(in drawingArea: CGRect) -> CGPoint {
    return abs(cxWithDefault, cyWithDefault, drawingArea)
  }

  var options: CGGradientDrawingOptions {
    return [.drawsAfterEndLocation, .drawsBeforeStartLocation]
  }

  func endRadius(in drawingArea: CGRect) -> CGFloat {
    return (r ?? 50%).abs(in: min(drawingArea.width, drawingArea.height))
  }
}

private func abs(
  _ x: SVG.Coordinate,
  _ y: SVG.Coordinate,
  _ area: CGRect
) -> CGPoint {
  return .init(
    x: area.origin.x + x.abs(in: area.size.width),
    y: area.origin.y + y.abs(in: area.size.height)
  )
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

postfix operator %
postfix func %(percent: SVG.Float) -> SVG.Coordinate {
  return .init(percent, .percent)
}
