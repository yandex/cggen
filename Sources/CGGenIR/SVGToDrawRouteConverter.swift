import CoreGraphics

import CGGenCore
import SVGParse

public enum SVGToDrawRouteConverter {
  public static func convert(document: SVG.Document) throws -> Routines {
    let boundingRect = document.boundingRect
    let height = boundingRect.size.height
    let gradients = try Dictionary(
      uniqueKeysWithValues: document.children.flatMap(gradients(svg:))
    )
    let filters = try Dictionary(
      uniqueKeysWithValues: document.children.flatMap(filters(svg:))
    )
    let defenitions = try defs(from: .svg(document))

    let pathRoutines: [PathRoutine] = defenitions
      .sorted { $0.key < $1.key } // Sort by ID for stable output
      .compactMap { id, svgs in
        guard id.hasPathPrefix,
              let svg = svgs.firstAndOnly,
              let content = pathSegmentsFromSVG(svg) else {
          return nil
        }
        return PathRoutine(id: id.withoutPathPrefix, content: content)
      }

    var context = Context(
      objectBoundingBox: boundingRect,
      drawingBounds: boundingRect,
      gradients: gradients.mapValues(\.0),
      filters: filters,
      defenitions: defenitions
    )
    let initialContextPrep =
      try context.apply(document.presentation, area: boundingRect)

    let drawRoutine = try DrawRoutine(
      boundingRect: boundingRect,
      gradients: gradients.mapValues(\.1),
      subroutines: [:],
      steps: [.concatCTM(.invertYAxis(height: height)), initialContextPrep] +
        document.children.map { try drawstep(svg: $0, ctx: &context)
        }
    )

    return Routines(drawRoutine: drawRoutine, pathRoutines: pathRoutines)
  }
}

public func pathSegmentsFromSVG(_ svg: SVG) -> [PathSegment]? {
  guard case let .path(path) = svg,
        case let .composite(segments) = try? pathConstruction(from: path.data)?
        .0 else {
    return nil
  }
  return segments
}

extension SVG.Document {
  var boundingRect: CGRect {
    CGRect(
      x: 0.0, y: 0.0,
      width: width?.number ?? 0,
      height: height?.number ?? 0
    )
  }
}

private typealias Defenitions = [String: [SVG]]

private enum Err: Swift.Error, @unchecked Sendable {
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
  case tooComplexFilter(SVGFilterNode)
  case invalidElementInClipPath(SVG)
  case ellipsesAreNotSupportedInPathsYet
}

private struct Context {
  private(set) var fill: SVG.Paint = .rgb(.black())
  private(set) var stroke: SVG.Paint = .none

  var objectBoundingBox: CGRect
  var drawingBounds: CGRect
  let gradients: [String: GradientStepsProvider]
  let filters: [String: SVGFilterNode]
  let defenitions: Defenitions

  init(
    objectBoundingBox: CGRect,
    drawingBounds: CGRect,
    gradients: [String: GradientStepsProvider],
    filters: [String: SVGFilterNode],
    defenitions: [String: [SVG]]
  ) {
    self.objectBoundingBox = objectBoundingBox
    self.drawingBounds = drawingBounds
    self.gradients = gradients
    self.filters = filters
    self.defenitions = defenitions
  }

  mutating func apply(
    _ presentation: SVG.PresentationAttributes,
    area: CGRect?
  ) throws -> DrawStep {
    fill ?= presentation.fill
    stroke ?= presentation.stroke
    objectBoundingBox ?= area

    let fillRule = presentation.fillRule.map { rule in
      DrawStep.fillRule(.init(rule))
    }

    let fill: DrawStep? = presentation.fill.flatMap { paint in
      switch paint {
      case let .rgb(color):
        return .fillColor(color.norm())
      case let .funciri(id: id):
        _ = id
        // TODO(): Implement
        return .fillNone
      case .none:
        return .fillNone
      }
    }

    let stroke: DrawStep? = presentation.stroke.flatMap { paint in
      switch paint {
      case let .rgb(color):
        return .strokeColor(color.norm())
      case let .funciri(id: id):
        _ = id
        // TODO(): Implement
        return .strokeNone
      case .none:
        return .strokeNone
      }
    }

    let strokeAlpha = presentation.strokeOpacity
      .map { DrawStep.strokeAlpha($0) }
    let fillAlpha = presentation.fillOpacity.map { DrawStep.fillAlpha($0) }

    let strokeWidth = try presentation.strokeWidth.map { l -> DrawStep in
      try check(
        l.unit != .percent, GenericError("Percent unit is not supported")
      )
      return DrawStep.lineWidth(CGFloat(l.number))
    }
    let strokeLineCap = presentation.strokeLineCap.map {
      DrawStep.lineCapStyle(.init(svgCap: $0))
    }
    let strokeLineJoin = presentation.strokeLineJoin.map {
      DrawStep.lineJoinStyle(.init(svgJoin: $0))
    }
    let strokeMiterlimit = presentation.strokeMiterlimit.map {
      DrawStep.miterLimit(CGFloat($0))
    }
    let mask = try presentation.mask.map { maskName -> DrawStep in
      guard case let .mask(svgmask)? = defenitions[maskName]?.firstAndOnly
      else {
        throw Err.noDefenitionForId(maskName)
      }
      return try stepsForMask(svgmask)
    }
    let clip = try presentation.clipPath.map { maskName -> DrawStep in
      guard case let .clipPath(clip)? = defenitions[maskName]?.firstAndOnly
      else {
        throw Err.noDefenitionForId(maskName)
      }
      return try stepsForClip(clip)
    }
    let filter = try presentation.filter.map { filterName -> DrawStep in
      let filter = try filters[filterName] !! Err.noDefenitionForId(filterName)
      return try .shadow(filter.simpleShadow !! Err.tooComplexFilter(filter))
    }

    return .composite([
      strokeWidth,
      strokeLineCap,
      strokeLineJoin,
      strokeMiterlimit,
      presentation.dashPatternUpdate,
      fillAlpha,
      fill,
      strokeAlpha,
      stroke,
      fillRule,
      mask,
      clip,
      filter,
    ].compactMap(identity))
  }

  func gradient(
    for paint: KeyPath<Context, SVG.Paint>,
    operation: PaintOpearion
  ) throws -> DrawStep? {
    if case let .funciri(grad) = self[keyPath: paint] {
      let g = try gradients[grad] !! Err.gradientNotFound(grad)
      return g((objectBoundingBox, drawingBounds, operation))
    }
    return nil
  }

  func drawPath(path: DrawStep) throws -> DrawStep {
    try .composite([
      gradient(for: \.fill, operation: .fill),
      gradient(for: \.stroke, operation: .stroke),
      path,
      DrawStep.fillAndStroke,
    ].compactMap(identity))
  }

  func stepsForMask(_ mask: SVG.Mask) throws -> DrawStep {
    try stepsForClipLike(children: mask.children, transform: mask.transform)
  }

  func stepsForClip(_ clip: SVG.ClipPath) throws -> DrawStep {
    try stepsForClipLike(children: clip.children, transform: clip.transform)
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
    let comps: [DrawStep?] = try [.saveGState, transform] +
      shapes.map { try $0.shapeConstruction()?.0 } +
      [.restoreGState, .clip]
    return .composite(comps.compactMap(identity))
  }
}

private func drawShape(
  pathConstruction: PathSegment,
  presentation: SVG.PresentationAttributes,
  transform: [SVG.Transform]?,
  area: CGRect,
  ctx: Context
) throws -> DrawStep {
  var ctx = ctx
  let strokeAndFill = try ctx.apply(presentation, area: area)
  // FIXME: Merge with same code in group
  var pre: [DrawStep] = [.saveGState, strokeAndFill]
  var post: [DrawStep] = []
  if let transform {
    pre += transform.map(CGAffineTransform.init).map(DrawStep.concatCTM)
  }
  if let opacity = presentation.opacity {
    pre.append(.globalAlpha(CGFloat(opacity)))
  }
  if presentation.opacity != nil || presentation.filter != nil {
    pre.append(.beginTransparencyLayer)
    post.append(.endTransparencyLayer)
  }
  post.append(.restoreGState)
  return try .composite(
    pre +
      [ctx.drawPath(path: .pathSegment(pathConstruction))] + post
  )
}

private func group(
  ctx: Context,
  presentation: SVG.PresentationAttributes,
  transform: [SVG.Transform]?,
  children: [SVG]
) throws -> DrawStep {
  var ctx = ctx
  let presentationSteps = try ctx.apply(presentation, area: nil)
  var pre: [DrawStep] = [.saveGState, presentationSteps]
  var post: [DrawStep] = []
  if let transform {
    pre += transform.map(CGAffineTransform.init).map(DrawStep.concatCTM)
  }
  if let opacity = presentation.opacity {
    pre.append(.globalAlpha(CGFloat(opacity)))
  }
  if presentation.opacity != nil || presentation.filter != nil {
    pre.append(.beginTransparencyLayer)
    post.append(.endTransparencyLayer)
  }
  post.append(.restoreGState)
  var childContext = ctx
  return try .composite(
    pre + children
      .map { try drawstep(svg: $0, ctx: &childContext) } + post
  )
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
    guard let (steps, box) = pathConstruction(from: r.data)
    else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: r.presentation,
      transform: r.transform,
      area: box,
      ctx: ctx
    )
  case let .polygon(shape):
    guard let (steps, box) = pathConstruction(from: shape.data)
    else { return .empty }

    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      transform: shape.transform,
      area: box,
      ctx: ctx
    )
  case let .circle(shape):
    guard let (steps, box) = pathConstruction(from: shape.data)
    else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      transform: shape.transform,
      area: box,
      ctx: ctx
    )
  case let .path(shape):
    guard let (steps, box) = try pathConstruction(from: shape.data)
    else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      transform: shape.transform,
      area: box,
      ctx: ctx
    )
  case let .ellipse(shape):
    guard let (steps, box) = pathConstruction(from: shape.data)
    else { return .empty }
    return try drawShape(
      pathConstruction: steps,
      presentation: shape.presentation,
      transform: shape.transform,
      area: box,
      ctx: ctx
    )
  }
}

private func pathConstruction(
  from rect: SVG.RectData
) -> (PathSegment, boundingBox: CGRect)? {
  let cgrect = CGRect(rect)
  let pathConstruction: PathSegment = switch (
    rect.rx.map { CGFloat($0.number) },
    rect.ry.map { CGFloat($0.number) }
  ) {
  case (nil, nil):
    .appendRectangle(cgrect)
  case let (rx?, nil):
    .appendRoundedRect(cgrect, rx: rx, ry: rx)
  case let (nil, ry?):
    .appendRoundedRect(cgrect, rx: ry, ry: ry)
  case let (rx?, ry?):
    .appendRoundedRect(cgrect, rx: rx, ry: ry)
  }
  return (pathConstruction, cgrect)
}

private func pathConstruction(
  from polygon: SVG.PolygonData
) -> (PathSegment, boundingBox: CGRect)? {
  guard let points = polygon.points else { return nil }
  let cgpoints = points.map {
    CGPoint(x: $0._1, y: $0._2)
  }
  let box: CGRect = CGPath.make {
    $0.addLines(between: cgpoints)
    $0.closeSubpath()
  }.boundingBox
  return (.composite([.lines(cgpoints), PathSegment.closePath]), box)
}

private func pathConstruction(
  from ellipse: SVG.EllipseData
) -> (PathSegment, boundingBox: CGRect)? {
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

private func pathConstruction(
  from circle: SVG.CircleData
) -> (PathSegment, boundingBox: CGRect)? {
  guard let r = circle.r else { return nil }
  let cx = circle.cx ?? 0
  let cy = circle.cy ?? 0
  let rect = CGRect.square(
    center: CGPoint(x: cx.number.cgfloat, y: cy.number.cgfloat),
    size: r.number.cgfloat * 2
  )
  return (.addEllipse(in: rect), rect)
}

// Adhoc helper to reset last control points, because it is annoying to
// reset them before every return statement, so reseting done via defer,
// but if control point was set – avoid reseting.
private struct Resetable<T> {
  private var ignoreNextReset = false
  private var valuePrivate: T?
  var value: T? {
    get {
      valuePrivate
    }
    set {
      ignoreNextReset = true
      valuePrivate = newValue
    }
  }

  mutating func reset() {
    guard !ignoreNextReset else { return ignoreNextReset = false }
    valuePrivate = nil
  }
}

private func pathConstruction(
  from path: SVG.PathData
) throws -> (PathSegment, boundingBox: CGRect)? {
  guard let commands = path.d else { return nil }
  let cgpath = CGMutablePath()
  var currentPoint: CGPoint?
  var subPathStartPoint: CGPoint?
  var prevCurveControlPoint = Resetable<CGPoint>()
  var prevQuadControlPoint = Resetable<CGPoint>()
  let steps: [PathSegment] = try commands.flatMap { command -> [PathSegment] in
    defer {
      prevCurveControlPoint.reset()
      prevQuadControlPoint.reset()
    }
    return try processCommandKind(
      command,
      cgPathAccumulator: cgpath,
      currentPoint: &currentPoint, subPathStartPoint: &subPathStartPoint,
      prevCurveControlPoint: &prevCurveControlPoint,
      prevQuadControlPoint: &prevQuadControlPoint
    )
  }
  return (.composite(steps), cgpath.boundingBox)
}

private func processCommandKind(
  _ command: SVG.PathData.Command,
  cgPathAccumulator cgpath: CGMutablePath,
  currentPoint: inout CGPoint?,
  subPathStartPoint: inout CGPoint?,
  prevCurveControlPoint: inout Resetable<CGPoint>,
  prevQuadControlPoint: inout Resetable<CGPoint>
) throws -> [PathSegment] {
  func point(
    for pair: SVG.CoordinatePair,
    _ currentPoint: CGPoint?
  ) throws -> CGPoint {
    let cgPoint = CGPoint(svgPair: pair)
    switch command.positioning {
    case .absolute:
      return cgPoint
    case .relative:
      guard let currentPoint else { throw Err.noPreviousPoint }
      return cgPoint + currentPoint
    }
  }

  switch command.kind {
  case .closepath:
    cgpath.closeSubpath()
    currentPoint = subPathStartPoint
    return [.closePath]
  case let .moveto(pairs):
    // Nonemptiness guaranteed by parser
    let first = CGPoint(svgPair: pairs.first!)
    let moveToPoint: CGPoint = if command.positioning == .relative,
                                  let currentPoint {
      currentPoint + first
    } else {
      first
    }
    let moveToStep = PathSegment.moveTo(moveToPoint)
    currentPoint = moveToPoint
    subPathStartPoint = moveToPoint
    cgpath.move(to: moveToPoint)

    return try [moveToStep] + pairs.dropFirst().map {
      let toPoint = try point(for: $0, currentPoint)
      cgpath.move(to: toPoint)
      currentPoint = toPoint
      return .lineTo(toPoint)
    }
  case let .lineto(pairs):
    return try pairs.map {
      let p = try point(for: $0, currentPoint)
      cgpath.addLine(to: p)
      currentPoint = p
      return .lineTo(p)
    }
  case let .curveto(args):
    return try args.map {
      let (cp1, cp2, to) = try (
        point(for: $0.cp1, currentPoint),
        point(for: $0.cp2, currentPoint),
        point(for: $0.to, currentPoint)
      )
      cgpath.addCurve(to: to, control1: cp1, control2: cp2)
      currentPoint = to
      prevCurveControlPoint.value = cp2
      return .curveTo(cp1, cp2, to)
    }
  /*
    8.3.6 The cubic Bézier curve commands
   Draws a cubic Bézier curve from the current point to (x,y). The first
   control point is assumed to be the reflection of the second control
   point on the previous command relative to the current point.
   (If there is no previous command or if the previous command
   was not an C, c, S or s, assume the first control point is coincident
   with the current point.)
   */
  case let .smoothCurveto(args):
    return try args.map {
      guard let current = currentPoint else { throw Err.noPreviousPoint }
      let cp1 = prevCurveControlPoint.value?
        .reflected(across: current) ?? current
      let (cp2, to) = try (
        point(for: $0.cp2, currentPoint),
        point(for: $0.to, currentPoint)
      )
      cgpath.addCurve(to: to, control1: cp1, control2: cp2)
      currentPoint = to
      prevCurveControlPoint.value = cp2
      return .curveTo(cp1, cp2, to)
    }
  case let .horizontalLineto(xs):
    return try xs.map { x in
      guard let current = currentPoint else { throw Err.noPreviousPoint }
      let modificator: (inout CGPoint) -> Void = switch command.positioning {
      case .absolute:
        { $0.x = x.cgfloat }
      case .relative:
        { $0.x += x.cgfloat }
      }
      let point = modified(current, modificator)
      cgpath.addLine(to: point)
      currentPoint = point
      return .lineTo(point)
    }
  case let .verticalLineto(ys):
    return try ys.map { y in
      guard let current = currentPoint else { throw Err.noPreviousPoint }
      let modificator: (inout CGPoint) -> Void = switch command.positioning {
      case .absolute:
        { $0.y = y.cgfloat }
      case .relative:
        { $0.y += y.cgfloat }
      }
      let point = modified(current, modificator)
      cgpath.addLine(to: point)
      currentPoint = point
      return .lineTo(point)
    }
  case let .ellipticalArc(args):
    return try args.map { arg in
      // See `8.3.8 The elliptical arc curve commands`
      let (rx, ry, xAxisRot, largeArcFlag, sweepFlag, toSVG) = arg.destruct()
      _ = xAxisRot // Applies only to ellipses, that are not supported yet
      let to = try point(for: toSVG, currentPoint)

      guard let current = currentPoint else { throw Err.noPreviousPoint }
      guard current != to else { return .empty }
      guard rx != 0 || ry != 0 else {
        // treat as line to
        cgpath.addLine(to: to)
        currentPoint = to
        return .lineTo(to)
      }
      try check(rx.isAlmostEqual(ry), Err.ellipsesAreNotSupportedInPathsYet)

      let rGiven = CGFloat(abs(rx))
      let fromToDistance = current.distance(to: to)
      let r = fromToDistance <= 2 * rGiven ? rGiven : fromToDistance / 2

      let center = solveCircleCenter(
        pointsOnCircle: (current, to),
        radius: r,
        anticlockwise: sweepFlag != largeArcFlag
      )
      let startAngle = CGVector(from: center, to: current).angle
      let endAngle = CGVector(from: center, to: to).angle

      cgpath.addArc(
        center: center,
        radius: r,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: !sweepFlag
      )
      currentPoint = to

      return .addArc(
        center: center,
        radius: r,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: !sweepFlag
      )
    }
  /*
     8.3.7 The quadratic Bézier curve commands
     Draws a quadratic Bézier curve from the current point to (x,y)
     using (x1,y1) as the control point.
   */
  case let .quadraticBezierCurveto(args):
    return try args.map {
      let (cp1, to) = try (
        point(for: $0.cp1, currentPoint),
        point(for: $0.to, currentPoint)
      )
      cgpath.addQuadCurve(to: to, control: cp1)
      currentPoint = to
      prevQuadControlPoint.value = cp1
      prevCurveControlPoint.value = nil
      return .quadCurveTo(cp1, to)
    }
  /*
     8.3.7 The quadratic Bézier curve commands
     T (smooth quadratic Bézier curveto)
     Draws a quadratic Bézier curve from the current point to (x,y).
     The control point is assumed to be the reflection of the control point
     on the previous command relative to the current point.
     (If there is no previous command or if the previous command was not
     a Q, q, T or t, assume the control point is coincident with the current point.)
   */
  case let .smoothQuadraticBezierCurveto(args):
    return try args.map {
      guard let current = currentPoint else { throw Err.noPreviousPoint }
      let cp1 = prevQuadControlPoint.value?
        .reflected(across: current) ?? current
      let to = try point(for: $0, currentPoint)

      cgpath.addQuadCurve(to: to, control: cp1)
      currentPoint = to
      prevQuadControlPoint.value = cp1
      prevCurveControlPoint.value = nil
      return .quadCurveTo(cp1, to)
    }
  }
}

enum PaintOpearion {
  case stroke, fill
}

typealias GradientStepsProvider = ((
  objectBoundingBox: CGRect,
  drawingBounds: CGRect,
  operation: PaintOpearion
)) -> DrawStep

private func gradients(
  svg: SVG
) throws -> [(String, (GradientStepsProvider, Gradient))] {
  switch svg {
  case let .defs(defs):
    return try defs.children.flatMap(gradients(svg:))
  case let .linearGradient(g):
    guard let id = g.core.id else { return [] }
    let stops = g.stops
    let locandcolors: [(CGFloat, RGBACGColor)] = stops.map {
      let color = $0.presentation.stopColor ?? SVG.Color(gray: 0, alpha: .zero)
      let opacity = CGFloat($0.presentation.stopOpacity ?? 1)
      let offset = switch $0.offset ?? .number(0) {
      case let .number(num):
        CGFloat(num)
      case let .percentage(percentage):
        CGFloat(percentage) / 100
      }
      return (offset, color.norm().withAlpha(opacity))
    }
    let gradient = Gradient(locationAndColors: locandcolors)
    let steps: GradientStepsProvider = { arg in
      let (objectBox, drawingArea, operation) = arg
      let coordinates: CGRect
      let unit = g.unit ?? .objectBoundingBox
      switch unit {
      case .objectBoundingBox:
        coordinates = objectBox
      case .userSpaceOnUse:
        coordinates = drawingArea
      }
      var startPoint = g.startPoint(in: coordinates)
      var endPoint = g.endPoint(in: coordinates)
      var transform = g.gradientTransform.map(makeTransform)
      if transform != nil, unit == .objectBoundingBox {
        startPoint.normalize(from: objectBox)
        endPoint.normalize(from: objectBox)
        transform?.adjustTo(objectBox)
      }
      let options = DrawStep.LinearGradientDrawingOptions(
        startPoint: startPoint,
        endPoint: endPoint,
        options: g.options,
        units: g.unit.map(DrawStep.Units.init) ?? .objectBoundingBox,
        transform: transform
      )
      switch operation {
      case .stroke:
        return .strokeLinearGradient(id, options)
      case .fill:
        return .fillLinearGradient(id, options)
      }
    }
    return [(id, (steps, gradient))]
  case let .radialGradient(g):
    guard let id = g.core.id else { return [] }
    let stops = g.stops
    let locandcolors: [(CGFloat, RGBACGColor)] = try stops.map {
      let color = try $0.presentation.stopColor !! Err.noStopColor
      let opacity = CGFloat($0.presentation.stopOpacity ?? 1)
      let offset = switch $0.offset ?? .number(0) {
      case let .number(num):
        CGFloat(num)
      case let .percentage(percentage):
        CGFloat(percentage) / 100
      }
      return (offset, color.norm().withAlpha(opacity))
    }
    let gradient = Gradient(locationAndColors: locandcolors)
    let steps: GradientStepsProvider = { arg in
      let (objectBox, drawingArea, operation) = arg
      let coordinates: CGRect
      let unit = g.unit ?? .objectBoundingBox
      switch unit {
      case .objectBoundingBox:
        coordinates = objectBox
      case .userSpaceOnUse:
        coordinates = drawingArea
      }
      var coordSpace = coordinates
      var transform = CGAffineTransform?.none
      if let gradientTransform = g.gradientTransform {
        coordSpace = drawingArea
        transform = makeTransform(from: gradientTransform)
        if unit == .objectBoundingBox {
          transform?.adjustTo(objectBox)
        }
      }
      let options = DrawStep.RadialGradientDrawingOptions(
        startCenter: g.startCenter(in: coordSpace),
        startRadius: 0,
        endCenter: g.endCenter(in: coordSpace),
        endRadius: g.endRadius(in: coordSpace),
        options: g.options,
        transform: transform
      )
      switch operation {
      case .stroke:
        return .strokeRadialGradient(id, options)
      case .fill:
        return .fillRadialGradient(id, options)
      }
    }
    return [(id, (steps, gradient))]
  default:
    return []
  }
}

private func makeTransform(
  from transforms: [SVG.Transform]
) -> CGAffineTransform {
  transforms.reversed().reduce(CGAffineTransform.identity) {
    $0.concatenating(.init(svgTransform: $1))
  }
}

private func filters(svg: SVG) throws -> [(String, SVGFilterNode)] {
  switch svg {
  case let .defs(defs):
    return try defs.children.flatMap(filters(svg:))
  case let .filter(f):
    let node = try SVGFilterNode(raw: f)
    guard let id = f.attributes.core.id else { return [] }
    return [(id, node)]
  default:
    return []
  }
}

private func defs(from svg: SVG) throws -> Defenitions {
  var result = Defenitions()
  if let _self = svg.core?.id {
    result[_self] = (result[_self] ?? []) + [svg]
  }
  if let children = svg.children {
    result = try children.map(defs(from:)).reduce(into: result) {
      $0.merge($1, uniquingKeysWith: +)
    }
  }
  return result
}

extension CGAffineTransform {
  mutating func adjustTo(_ objectBox: CGRect) {
    let scaleTransform = CGAffineTransform(
      scaleX: objectBox.width,
      y: objectBox.height
    )
    let translationTransform = CGAffineTransform(
      translationX: objectBox.origin.x,
      y: objectBox.origin.y
    )
    self = concatenating(scaleTransform).concatenating(translationTransform)
  }
}

extension SVG {
  var core: SVG.CoreAttributes? {
    switch self {
    case let .svg(svg):
      svg.core
    case let .group(group):
      group.core
    case let .use(e):
      e.core
    case let .rect(e):
      e.core
    case let .polygon(e):
      e.core
    case let .circle(e):
      e.core
    case let .ellipse(e):
      e.core
    case let .path(e):
      e.core
    case let .mask(e):
      e.core
    case let .defs(e):
      e.core
    case .title:
      nil
    case .desc:
      nil
    case let .linearGradient(e):
      e.core
    case let .radialGradient(e):
      e.core
    case let .clipPath(e):
      e.core
    case let .filter(e):
      e.core
    }
  }

  var children: [SVG]? {
    switch self {
    case let .svg(e):
      e.children
    case let .group(e):
      e.children
    case let .mask(e):
      e.children
    case let .clipPath(e):
      e.children
    case let .defs(e):
      e.children
    case .use, .rect, .polygon, .circle, .ellipse, .path, .title, .desc,
         .linearGradient, .radialGradient, .filter:
      nil
    }
  }
}

extension SVG.Shape {
  func shapeConstruction() throws -> (DrawStep, CGRect)? {
    try shapeConstructionWithoutTransform().map { path, box in
      let transformed = transform.flatMap(DrawStep.concatCTM).map {
        DrawStep.savingGState($0, .pathSegment(path))
      }
      return (transformed ?? .pathSegment(path), box)
    }
  }

  private func shapeConstructionWithoutTransform(
  ) throws -> (PathSegment, CGRect)? {
    switch self {
    case let .circle(e):
      pathConstruction(from: e.data)
    case let .path(e):
      try pathConstruction(from: e.data)
    case let .rect(e):
      pathConstruction(from: e.data)
    case let .ellipse(e):
      pathConstruction(from: e.data)
    case let .polygon(e):
      pathConstruction(from: e.data)
    }
  }

  var transform: [SVG.Transform]? {
    switch self {
    case let .circle(e):
      e.transform
    case let .path(e):
      e.transform
    case let .rect(e):
      e.transform
    case let .ellipse(e):
      e.transform
    case let .polygon(e):
      e.transform
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
        zipLongest(use.transform, translate, fillFirst: [], fillSecond: [])
          .map(+)
      return try .group(.init(
        core: use.core,
        presentation: use.presentation,
        transform: summaryTransform,
        children: [def.resolvingUses(from: defenitions)]
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
    CGRect(center: center, width: size, height: size)
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
  static let none = RGBACGColor(
    red: .zero,
    green: .zero,
    blue: .zero,
    alpha: .zero
  )
}

extension CGAffineTransform {
  init(svgTransform: SVG.Transform) {
    switch svgTransform {
    case let .translate(tx: tx, ty: ty):
      self.init(translationX: CGFloat(tx), y: CGFloat(ty ?? 0))
    case let .scale(sx: sx, sy: sy):
      self.init(scaleX: CGFloat(sx), y: CGFloat(sy ?? sx))
    case let .rotate(angle: angle, anchor: nil):
      self.init(rotationAngle: angle.radians)
    case let .rotate(angle: angle, anchor: anchor?):
      let cx = CGFloat(anchor.cx)
      let cy = CGFloat(anchor.cy)
      self = CGAffineTransform(translationX: -cx, y: -cy)
        .concatenating(.init(rotationAngle: angle.radians))
        .concatenating(.init(translationX: cx, y: cy))
    case let .skewX(val):
      self.init(a: 1, b: 0, c: tan(val.radians), d: 1, tx: 0, ty: 0)
    case let .skewY(val):
      self.init(a: 1, b: tan(val.radians), c: 0, d: 1, tx: 0, ty: 0)
    case let .matrix(a, b, c, d, e, f):
      self.init(
        a: CGFloat(a),
        b: CGFloat(b),
        c: CGFloat(c),
        d: CGFloat(d),
        tx: CGFloat(e),
        ty: CGFloat(f)
      )
    }
  }
}

extension CGPoint {
  mutating func normalize(from objectBox: CGRect) {
    self = CGPoint(
      x: (x - objectBox.origin.x) / objectBox.width,
      y: (y - objectBox.origin.y) / objectBox.height
    )
  }
}

extension SVG.LinearGradient {
  func startPoint(in drawingArea: CGRect) -> CGPoint {
    abs(x1 ?? 0%, y1 ?? 0%, drawingArea)
  }

  func endPoint(in drawingArea: CGRect) -> CGPoint {
    abs(x2 ?? 100%, y2 ?? 0%, drawingArea)
  }

  var options: CGGradientDrawingOptions {
    [.drawsAfterEndLocation, .drawsBeforeStartLocation]
  }
}

extension SVG.RadialGradient {
  private var cxWithDefault: SVG.Coordinate { cx ?? 50% }
  private var cyWithDefault: SVG.Coordinate { cy ?? 50% }

  func startCenter(in drawingAres: CGRect) -> CGPoint {
    abs(fx ?? cxWithDefault, fy ?? cyWithDefault, drawingAres)
  }

  func endCenter(in drawingArea: CGRect) -> CGPoint {
    abs(cxWithDefault, cyWithDefault, drawingArea)
  }

  var options: CGGradientDrawingOptions {
    [.drawsAfterEndLocation, .drawsBeforeStartLocation]
  }

  func endRadius(in drawingArea: CGRect) -> CGFloat {
    (r ?? 50%).abs(in: min(drawingArea.width, drawingArea.height))
  }
}

private func abs(
  _ x: SVG.Coordinate,
  _ y: SVG.Coordinate,
  _ area: CGRect
) -> CGPoint {
  .init(
    x: area.origin.x + x.abs(in: area.size.width),
    y: area.origin.y + y.abs(in: area.size.height)
  )
}

extension SVG.Coordinate {
  func abs(in value: CGFloat) -> CGFloat {
    switch unit {
    case nil, .pt?, .px?:
      CGFloat(number)
    case .percent?:
      CGFloat(number / 100) * value
    }
  }
}

extension SVG.Angle {
  var radians: CGFloat { CGFloat(degrees) * .pi / 180 }
}

extension SVG.Paint {
  var color: SVG.Color? {
    switch self {
    case let .rgb(color):
      color
    case .funciri, .none:
      nil
    }
  }
}

postfix operator %
postfix func %(percent: SVG.Float) -> SVG.Coordinate {
  .init(percent, .percent)
}

extension DrawStep {
  fileprivate static func concatCTM(
    svgTransform: [SVG.Transform]
  ) -> DrawStep? {
    let t = svgTransform.reduce(CGAffineTransform.identity) {
      $0.concatenating(.init(svgTransform: $1))
    }
    if t == CGAffineTransform.identity { return nil }
    return .concatCTM(t)
  }
}

extension SVGFilterNode {
  fileprivate var simpleShadow: Shadow? {
    guard case let .blend(in1: .sourceGraphic, in2: preShadow, .normal) = self,
          var shadow = preShadow.meaningfulPart
    else { return nil }

    var offset: CGSize?
    var blur: CGFloat?
    var alphaAndColor: (SVG.Float, RGBACGColor)?
    var alphaBurned = false

    outer: while true {
      switch shadow {
      case .sourceAlpha, .sourceGraphic:
        break outer
      case let .colorMatrix(in: input, type: .matrix(matrix)):
        guard let alphaAndColorFromMatrix = matrix.ifAlphaMultiplication else {
          return nil
        }
        if alphaAndColor == nil {
          alphaAndColor = alphaAndColorFromMatrix
        } else if !alphaBurned, alphaAndColorFromMatrix.alpha >= 100 {
          alphaBurned = true
        } else {
          return nil
        }
        shadow = input
      case let .offset(in: input, dx: dx, dy: dy):
        guard offset == nil else { return nil }
        offset = CGSize(width: dx, height: dy)
        shadow = input
      case let .gaussianBlur(in: input, stddevX: stddevX, stddevY: stddevY):
        guard !alphaBurned, blur == nil, stddevX == stddevY else { return nil }
        // See `15.17 Filter primitive 'feGaussianBlur'` in specs.
        // Here we don't know the resulting ctm yet, so we can't add 0.5 and
        // floor it. That is done on codegen level for now.
        blur = CGFloat(stddevX) * 3 * sqrt(2 * .pi) / 4
        shadow = input
      default:
        return nil
      }
    }
    guard alphaBurned else { return nil }
    return zip(blur, alphaAndColor).map { arg -> Shadow in
      let (blur, alphaAndColor) = arg
      // As shadows alpha channel is burned we can add multiplier and constant
      // parts
      // From specs: A' = a1*R + a2*G + a3*B + a4*A + a5
      // a1, a2, a3 are zero, A is burned to 1, so it simplifies:
      // A' = a4 + a5
      let color = modified(alphaAndColor.1) { $0.alpha += alphaAndColor.0 }
      return .init(
        offset: offset ?? .zero,
        blur: blur,
        color: color
      )
    }
  }

  private var meaningfulPart: SVGFilterNode? {
    guard isMeaningful else { return nil }
    if case let .blend(in1: in1, in2: in2, _) = self {
      switch (in1.meaningfulPart, in2.meaningfulPart) {
      case (_?, _?): // Both inputs are meaningfull
        return self
      case let (in1?, nil):
        return in1
      case let (nil, in2?):
        return in2
      case (nil, nil):
        return nil
      }
    }

    return self
  }

  private var isMeaningful: Bool {
    if case .flood(color: _, opacity: 0) = self {
      return false
    }

    return true
  }
}

extension SVGFilterNode.ColorMatrix {
  var ifAlphaMultiplication: (alpha: SVG.Float, color: RGBACGColor)? {
    // Check if input color doesn't affect output
    let isConst: (T) -> Bool = {
      $0.c1.isAlmostZero() && $0.c2.isAlmostZero() && $0.c3.isAlmostZero() &&
        $0.c4.isAlmostZero()
    }
    guard isConst(r1), isConst(r2), isConst(r3),
          isConst(r4) || !r4.c4
          .isAlmostZero() // Allow nonzero alpha multiplier
    else { return nil }
    let color = RGBACGColor(red: r1.c5, green: r2.c5, blue: r3.c5, alpha: r4.c5)
    return (r4.c4, color)
  }
}

extension SVG.PresentationAttributes {
  var dashPatternUpdate: DrawStep? {
    let lengths: [CGFloat]? = strokeDashArray.flatMap { lengths in
      guard lengths.count > 0 else { return nil }
      let lenghts = lengths.map { CGFloat($0.number) }
      if lengths.count.isMultiple(of: 2) {
        return lenghts
      } else {
        return lenghts + lenghts
      }
    }
    let phase = strokeDashOffset.map { CGFloat($0.number) }
    switch (phase, lengths) {
    case let (phase?, lengths?):
      return .dash(.init(phase: phase, lengths: lengths))
    case let (phase?, nil):
      return .dashPhase(phase)
    case let (nil, lengths?):
      return .dashLengths(lengths)
    case (nil, nil):
      return nil
    }
  }
}

extension DrawStep.Units {
  fileprivate init(_ svg: SVG.Units) {
    switch svg {
    case .objectBoundingBox:
      self = .objectBoundingBox
    case .userSpaceOnUse:
      self = .userSpaceOnUse
    }
  }
}

extension String {
  var hasPathPrefix: Bool {
    hasPrefix(pathPrefix)
  }

  var withoutPathPrefix: String {
    guard hasPathPrefix else { return self }
    return String(dropFirst(pathPrefix.count))
  }
}

private let pathPrefix = "cggen."
