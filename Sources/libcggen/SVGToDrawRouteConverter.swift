import Base
import CoreGraphics

enum SVGToDrawRouteConverter {
  static func convert(document: SVG.Document) throws -> DrawRoute {
    let boundingRect = document.boundingRect
    let height = boundingRect.size.height
    let gradients = try Dictionary(
      uniqueKeysWithValues: document.children.flatMap(gradients(svg:))
    )
    let defenitions = try defs(from: document)
    var context = Context(
      objectBoundingBox: boundingRect,
      drawingBounds: boundingRect,
      gradients: gradients.mapValues { $0.1 },
      defenitions: defenitions
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
      height: height?.number ?? 0
    )
  }
}

private enum Err: Swift.Error {
  case widthLessThan0(SVG.Rect)
  case heightLessThan0(SVG.Rect)
  case noStopColor
  case noStopOffset
  case gradientNotFound(String)
  case noPreviousPoint
  case multipleDefenitionsForId(e1: SVG, e2: SVG)
  case noDefenitionForId(String)
  case noRefInUseElement(SVG.Use)
}

private struct Context {
  private(set) var fillRule: SVG.FillRule = .evenodd
  private(set) var fillAlpha: SVG.Float = 1
  private(set) var fill: SVG.Paint = .rgb(.black())
  private(set) var strokeAlpha: SVG.Float = 1
  private(set) var stroke: SVG.Paint = .none
  private(set) var strokeWidth: SVG.Length = 1
  private(set) var strokeDashArray: [SVG.Length] = []
  private(set) var strokeDashOffset: SVG.Length = 0

  var currentFill: RGBAColorType<UInt8, SVG.Float>?
  var currentStroke: RGBAColorType<UInt8, SVG.Float>?
  var objectBoundingBox: CGRect
  var drawingBounds: CGRect
  let gradients: [String: GradientStepsProvider]
  let defenitions: [String: SVG]

  init(
    objectBoundingBox: CGRect,
    drawingBounds: CGRect,
    gradients: [String: GradientStepsProvider],
    defenitions: [String: SVG]
  ) {
    self.objectBoundingBox = objectBoundingBox
    self.drawingBounds = drawingBounds
    self.gradients = gradients
    self.defenitions = defenitions
  }

  mutating func updateCurrentFillAndStroke() -> DrawStep {
    func color(
      paint: SVG.Paint,
      opacity: SVG.Float,
      current: inout RGBAColorType<UInt8, SVG.Float>?
    ) -> RGBACGColor? {
      guard let color = paint.color else {
        current = nil
        return nil
      }
      let new = color.withAlpha(opacity)
      guard current != new else {
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
    objectBoundingBox ?= area

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
      return g((objectBoundingBox, drawingBounds))
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

private func group(ctx: inout Context, presentation: SVG.PresentationAttributes, transform: [SVG.Transform]?, children: [SVG]) throws -> DrawStep {
  let presentationSteps = ctx.apply(presentation, area: nil)
  var pre: [DrawStep] = [.saveGState, presentationSteps]
  var post: [DrawStep] = []
  if let transform = transform {
    pre += transform.map(CGAffineTransform.init).map(DrawStep.concatCTM)
  }
  if let opacity = presentation.opacity {
    pre += [.globalAlpha(CGFloat(opacity)), .beginTransparencyLayer]
    post.append(.endTransparencyLayer)
  }
  post.append(.restoreGState)
  var childContext = ctx
  return try .composite(pre + children.map { try drawstep(svg: $0, ctx: &childContext) } + post)
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
    return try group(
      ctx: &ctx,
      presentation:
      g.presentation,
      transform: g.transform,
      children: g.children
    )
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
  case let .use(use):
    let ref = try use.xlinkHref !! Err.noRefInUseElement(use)
    let def = try ctx.defenitions[ref] !! Err.noDefenitionForId(ref)
    let translate = zip(use.x, use.y).map { SVG.Transform.translate(tx: $0.0.number, ty: $0.1.number) }
    let summaryTransform: [SVG.Transform]?
    switch (use.transform, translate) {
    case let (use?, translate?):
      summaryTransform = [translate] + use
    case let (nil, translate?):
      summaryTransform = [translate]
    case let (use?, nil):
      summaryTransform = use
    case (nil, nil):
      summaryTransform = nil
    }
    return try group(ctx: &ctx, presentation: use.presentation, transform: summaryTransform, children: [def])
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
    var currentPoint: CGPoint?
    let path: [DrawStep] = try commands.flatMap { (command) -> [DrawStep] in
      guard let move = command.moveTo.last else { return [DrawStep.empty] }
      let point = CGPoint(svgPair: move.coordinatePair)
      cgpath.move(to: point)
      currentPoint = point
      return try [DrawStep.moveTo(point)] + command.drawTo.map {
        switch $0 {
        case .closepath:
          cgpath.closeSubpath()
          currentPoint = nil
          return .closePath
        case let .lineto(_, pair):
          let point = CGPoint(svgPair: pair)
          cgpath.addLine(to: point)
          currentPoint = point
          return .lineTo(point)
        case let .curveto(_, cp1, cp2, to):
          let cp1 = CGPoint(svgPair: cp1)
          let cp2 = CGPoint(svgPair: cp2)
          let to = CGPoint(svgPair: to)
          currentPoint = to
          return .curveTo(cp1, cp2, to)
        case let .horizontalLineto(_, x):
          guard let current = currentPoint else { throw Err.noPreviousPoint }
          let point = modified(current) { $0.x = x.cgfloat }
          currentPoint = point
          return .lineTo(point)
        case let .verticalLineto(_, y):
          guard let current = currentPoint else { throw Err.noPreviousPoint }
          let point = modified(current) { $0.y = y.cgfloat }
          currentPoint = point
          return .lineTo(point)
        case .smoothCurveto, .quadraticBezierCurveto,
             .smoothQuadraticBezierCurveto:
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

typealias GradientStepsProvider = ((
  objectBoundingBox: CGRect,
  drawingBounds: CGRect
)) -> DrawStep

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
      switch $0.offset ?? .number(0) {
      case let .number(num):
        offset = CGFloat(num)
      case let .percentage(percentage):
        offset = CGFloat(percentage) / 100
      }
      return (offset, color.norm().withAlpha(opacity))
    }
    let steps: GradientStepsProvider = { arg in
      let (objectBox, drawingArea) = arg
      let coordinates: CGRect
      switch g.unit ?? .objectBoundingBox {
      case .objectBoundingBox:
        coordinates = objectBox
      case .userSpaceOnUse:
        coordinates = drawingArea
      }
      return .linearGradient(id, (
        startPoint: g.startPoint(in: coordinates),
        endPoint: g.endPoint(in: coordinates),
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
      switch $0.offset ?? .number(0) {
      case let .number(num):
        offset = CGFloat(num)
      case let .percentage(percentage):
        offset = CGFloat(percentage) / 100
      }
      return (offset, color.norm().withAlpha(opacity))
    }
    let steps: GradientStepsProvider = { arg in
      let (objectBox, drawingArea) = arg
      let coordinates: CGRect
      switch g.unit ?? .objectBoundingBox {
      case .objectBoundingBox:
        coordinates = objectBox
      case .userSpaceOnUse:
        coordinates = drawingArea
      }
      return .radialGradient(id, (
        startCenter: g.startCenter(in: coordinates),
        startRadius: 0,
        endCenter: g.endCenter(in: coordinates),
        endRadius: g.endRadius(in: coordinates),
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

private func defs(from svg: SVG.Document) throws -> [String:SVG] {
  return try svg.children.reduce(into: [String:SVG]()) {
    guard case let .defs(defs) = $1 else { return }
    let pairs = defs.children.compactMap { (child) -> (String, SVG)? in
      guard let id = child.core?.id else { return nil }
      return (id, child)
    }
    return try $0.merge(pairs) {
      throw Err.multipleDefenitionsForId(e1: $0, e2: $1)
    }
  }
}

extension SVG {
  var core: SVG.CoreAttributes? {
    switch self {
    case let .svg(svg):
      return svg.core
    case let .group(group):
      return group.core
    case let .use(e):
      return e.core
    case let .rect(e):
      return e.core
    case let .polygon(e):
      return e.core
    case let .circle(e):
      return e.core
    case let .ellipse(e):
      return e.core
    case let .path(e):
      return e.core
    case .mask:
      return nil
    case let .defs(e):
      return e.core
    case .title:
      return nil
    case .desc:
      return nil
    case let .linearGradient(e):
      return e.core
    case let .radialGradient(e):
      return e.core
    }
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
      return CGFloat(number)
    case .percent?:
      return CGFloat(number / 100) * value
    }
  }
}

extension SVG.Paint {
  var color: SVG.Color? {
    switch self {
    case let .rgb(color):
      return color
    case .funciri, .none:
      return nil
    }
  }
}

postfix operator %
postfix func %(percent: SVG.Float) -> SVG.Coordinate {
  return .init(percent, .percent)
}
