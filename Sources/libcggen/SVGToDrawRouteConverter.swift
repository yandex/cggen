import Base
import CoreGraphics

enum SVGToDrawRouteConverter {
  static func convert(document: SVG.Document) throws -> DrawRoute {
    let boundingRect = document.boundingRect
    let height = boundingRect.size.height
    let gradients = try Dictionary(
      uniqueKeysWithValues: document.children.flatMap(gradients(svg:))
    )
    let defenitions = try defs(from: .svg(document))
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

private typealias Defenitions = [String: [SVG]]

private enum Err: Swift.Error {
  case widthLessThan0(SVG.Rect)
  case heightLessThan0(SVG.Rect)
  case noStopColor
  case noStopOffset
  case gradientNotFound(String)
  case noPreviousPoint
  case multipleDefenitionsForId(String)
  case noDefenitionForId(String)
  case invalidTypeForIRI(String, expected: String, got: SVG)
  case noRefInUseElement(SVG.Use)
  case emptyMask(SVG.Shape)
  case tooComplexMask(SVG.Mask)
  case invalidElementInClipPath(SVG)
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
  let defenitions: Defenitions

  init(
    objectBoundingBox: CGRect,
    drawingBounds: CGRect,
    gradients: [String: GradientStepsProvider],
    defenitions: [String: [SVG]]
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
  ) throws -> DrawStep {
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
    let mask = try presentation.mask.map { (maskName) -> DrawStep in
      guard case let .mask(svgmask)? = defenitions[maskName]?.firstAndOnly else {
        throw Err.noDefenitionForId(maskName)
      }
      return try stepsForMask(svgmask)
    }
    let clip = try presentation.clipPath.map { (maskName) -> DrawStep in
      guard case let .clipPath(clip)? = defenitions[maskName]?.firstAndOnly else {
        throw Err.noDefenitionForId(maskName)
      }
      return try stepsForClip(clip)
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
      mask,
      clip,
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

  func stepsForMask(_ mask: SVG.Mask) throws -> DrawStep {
    return try stepsForClipLike(children: mask.children, transform: mask.transform)
  }

  func stepsForClip(_ clip: SVG.ClipPath) throws -> DrawStep {
    return try stepsForClipLike(children: clip.children, transform: clip.transform)
  }

  private func stepsForClipLike(
    children: [SVG],
    transform: [SVG.Transform]?
  ) throws -> DrawStep {
    let shapes: [SVG.Shape] = try children.map {
      if let shape = $0.shape {
        return shape
      }
      if case let .use(use) = $0,
        let ref = use.xlinkHref,
        let shape = defenitions[ref]?.firstAndOnly?.shape {
        return shape
      }
      throw Err.invalidElementInClipPath($0)
    }
    let transform = transform.map {
      DrawStep.concatCTM($0.reduce(CGAffineTransform.identity) {
        $0.concatenating(.init(svgTransform: $1))
      })
    }
    return try .composite(
      [.saveGState] +
        [transform ?? .empty] +
        shapes.compactMap { try $0.shapeConstruction()?.0 } +
        [.saveGState] +
        [.clip(.init(fillRule))]
    )
  }
}

private func drawShape(
  pathConstruction: DrawStep,
  presentation: SVG.PresentationAttributes,
  area: CGRect,
  ctx: Context
) throws -> DrawStep {
  var ctx = ctx
  let strokeAndFill = try ctx.apply(presentation, area: area)
  return try .composite([
    .saveGState,
    strokeAndFill,
    ctx.drawPath(path: pathConstruction),
    .restoreGState,
  ])
}

private func group(ctx: Context, presentation: SVG.PresentationAttributes, transform: [SVG.Transform]?, children: [SVG]) throws -> DrawStep {
  var ctx = ctx
  let presentationSteps = try ctx.apply(presentation, area: nil)
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
  case .title, .desc:
    return .empty
  case let .group(g):
    return try group(
      ctx: ctx,
      presentation:
      g.presentation,
      transform: g.transform,
      children: g.children
    )
  case .svg:
    fatalError()
  case .linearGradient, .radialGradient, .filter:
    return .empty
  case .use:
    // FIXME: There gotta be more clever way than just inlining everything
    let resolved = try svg.resolvingUses(from: ctx.defenitions)
    return try drawstep(svg: resolved, ctx: &ctx)
  case .defs, .mask, .clipPath:
    return .empty
  case let .rect(r):
    guard let (steps, box) = pathConstruction(from: r.data) else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: r.presentation,
      area: box,
      ctx: ctx
    )
  case let .polygon(shape):
    guard let (steps, box) = pathConstruction(from: shape.data) else { return .empty }

    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      area: box,
      ctx: ctx
    )
  case let .circle(shape):
    guard let (steps, box) = pathConstruction(from: shape.data) else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      area: box,
      ctx: ctx
    )
  case let .path(shape):
    guard let (steps, box) = try pathConstruction(from: shape.data) else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      area: box,
      ctx: ctx
    )
  case let .ellipse(shape):
    guard let (steps, box) = pathConstruction(from: shape.data) else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      area: box,
      ctx: ctx
    )
  }
}

private func pathConstruction(from rect: SVG.RectData) -> (DrawStep, boundingBox: CGRect)? {
  let cgrect = CGRect(rect)
  let pathConstruction: DrawStep
  switch (rect.rx.map { CGFloat($0.number) }, rect.ry.map { CGFloat($0.number) }) {
  case (nil, nil):
    pathConstruction = .appendRectangle(cgrect)
  case let (rx?, nil):
    pathConstruction = .appendRoundedRect(cgrect, rx: rx, ry: rx)
  case let (nil, ry?):
    pathConstruction = .appendRoundedRect(cgrect, rx: ry, ry: ry)
  case let (rx?, ry?):
    pathConstruction = .appendRoundedRect(cgrect, rx: rx, ry: ry)
  }
  return (pathConstruction, cgrect)
}

private func pathConstruction(from polygon: SVG.PolygonData) -> (DrawStep, boundingBox: CGRect)? {
  guard let points = polygon.points else { return nil }
  let cgpoints = points.map {
    CGPoint(x: $0._1, y: $0._2)
  }
  let box: CGRect = CGPath.make {
    $0.addLines(between: cgpoints)
    $0.closeSubpath()
  }.boundingBox
  return (.composite([.lines(cgpoints), .closePath]), box)
}

private func pathConstruction(from ellipse: SVG.EllipseData) -> (DrawStep, boundingBox: CGRect)? {
  guard let cx = ellipse.cx, let cy = ellipse.cy,
    let rx = ellipse.rx, let ry = ellipse.ry,
    rx.number != 0, ry.number != 0 else { return nil }
  let rect = CGRect(
    center: CGPoint(x: cx.number.cgfloat, y: cy.number.cgfloat),
    width: rx.number.cgfloat * 2,
    height: ry.number.cgfloat * 2
  )
  return (.addEllipse(in: rect), rect)
}

private func pathConstruction(from circle: SVG.CircleData) -> (DrawStep, boundingBox: CGRect)? {
  guard let cx = circle.cx, let cy = circle.cy, let r = circle.r else { return nil }
  let rect = CGRect.square(
    center: CGPoint(x: cx.number.cgfloat, y: cy.number.cgfloat),
    size: r.number.cgfloat * 2
  )
  return (.addEllipse(in: rect), rect)
}

private func pathConstruction(from path: SVG.PathData) throws -> (DrawStep, boundingBox: CGRect)? {
  guard let commands = path.d else { return nil }
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
  return (.composite(path), cgpath.boundingBox)
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

private func defs(from svg: SVG) throws -> Defenitions {
  var result = Defenitions()
  if let parent = svg.core?.id {
    result[parent] = (result[parent] ?? []) + [svg]
  }
  if let children = svg.children {
    result = try children.map(defs(from:)).reduce(into: result) {
      $0.merge($1, uniquingKeysWith: +)
    }
  }
  return result
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
    case let .mask(e):
      return e.core
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
    case let .clipPath(e):
      return e.core
    case let .filter(e):
      return e.core
    }
  }

  var children: [SVG]? {
    switch self {
    case let .svg(e):
      return e.children
    case let .group(e):
      return e.children
    case let .mask(e):
      return e.children
    case let .clipPath(e):
      return e.children
    case let .defs(e):
      return e.children
    case .use, .rect, .polygon, .circle, .ellipse, .path, .title, .desc,
         .linearGradient, .radialGradient, .filter:
      return nil
    }
  }
}

extension SVG.Shape {
  func shapeConstruction() throws -> (DrawStep, CGRect)? {
    return try shapeConstructionWithoutTransform().map { path, box in
      let transformed = transform.flatMap(DrawStep.concatCTM).map {
        DrawStep.savingGState($0, path)
      }
      return (transformed ?? path, box)
    }
  }

  private func shapeConstructionWithoutTransform() throws -> (DrawStep, CGRect)? {
    switch self {
    case let .circle(e):
      return pathConstruction(from: e.data)
    case let .path(e):
      return try pathConstruction(from: e.data)
    case let .rect(e):
      return pathConstruction(from: e.data)
    case let .ellipse(e):
      return pathConstruction(from: e.data)
    case let .polygon(e):
      return pathConstruction(from: e.data)
    }
  }

  var transform: [SVG.Transform]? {
    switch self {
    case let .circle(e):
      return e.transform
    case let .path(e):
      return e.transform
    case let .rect(e):
      return e.transform
    case let .ellipse(e):
      return e.transform
    case let .polygon(e):
      return e.transform
    }
  }
}

extension SVG {
  fileprivate func resolvingUses(from defenitions: Defenitions) throws -> SVG {
    switch self {
    case let .use(use):
      let ref = try use.xlinkHref !! Err.noRefInUseElement(use)
      let defs = try defenitions[ref] !! Err.noDefenitionForId(ref)
      let def = try defs.first !! Err.noDefenitionForId(ref)
      try check(defs.count == 1, Err.multipleDefenitionsForId(ref))
      let translate = zipLongest(use.x, use.y, fillFirst: 0, fillSecond: 0)
        .map { [SVG.Transform.translate(tx: $0.0.number, ty: $0.1.number)] }
      let summaryTransform =
        zipLongest(use.transform, translate, fillFirst: [], fillSecond: []).map(+)
      return .group(.init(
        core: use.core,
        presentation: use.presentation,
        transform: summaryTransform,
        children: [try def.resolvingUses(from: defenitions)]
      ))
    default:
      return self
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
  init(_ r: SVG.RectData) {
    let cg: (KeyPath<SVG.RectData, SVG.Coordinate?>) -> CGFloat = {
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

extension DrawStep {
  fileprivate static func concatCTM(svgTransform: [SVG.Transform]) -> DrawStep? {
    let t = svgTransform.reduce(CGAffineTransform.identity) {
      $0.concatenating(.init(svgTransform: $1))
    }
    if t == CGAffineTransform.identity { return nil }
    return .concatCTM(t)
  }
}
