import Compression
import CoreGraphics
import Foundation

import BCCommon

public func runBytecode(_ context: CGContext, fromData data: Data) throws {
  let sz = data.count
  try data.withUnsafeBytes {
    let ptr = $0.baseAddress!
    try BytecodeRunner.run(context, ptr, sz)
  }
}

public func runPathBytecode(_ path: CGMutablePath, fromData data: Data) throws {
  let sz = data.count
  try data.withUnsafeBytes {
    let ptr = $0.baseAddress!
    try PathBytecodeRunner.run(path, ptr, sz)
  }
}

public func runMergedBytecode(
  fromData data: Data,
  _ context: CGContext,
  _ decompressedLen: Int,
  _ startIndex: Int,
  _ endIndex: Int
) throws {
  let sz = data.count
  try data.withUnsafeBytes {
    let ptr = $0.baseAddress!.assumingMemoryBound(to: UInt8.self)

    let decompressedArray = try cache[ptr] ?? {
      let bytecode = try decompressBytecode(ptr, sz, decompressedLen)
      cache[ptr] = bytecode
      return bytecode
    }()

    let partArray = Array(decompressedArray[startIndex...endIndex])
    try BytecodeRunner.run(context, partArray, partArray.count)
  }
}

@_cdecl("runMergedBytecode")
public func runMergedBytecode(
  _ context: CGContext,
  _ start: UnsafePointer<UInt8>,
  _ decompressedLen: Int,
  _ len: Int,
  _ startIndex: Int,
  _ endIndex: Int
) {
  do {
    let decompressedArray = try cache[start] ?? {
      let bytecode = try decompressBytecode(start, len, decompressedLen)
      cache[start] = bytecode
      return bytecode
    }()

    let partArray = Array(decompressedArray[startIndex...endIndex])
    try BytecodeRunner.run(context, partArray, partArray.count)
  } catch let t {
    assertionFailure("Failed to run bytecode with error: \(t)")
  }
}

@_cdecl("runBytecode")
public func runBytecode(
  _ context: CGContext,
  _ start: UnsafePointer<UInt8>,
  _ len: Int
) {
  do {
    try BytecodeRunner.run(context, start, len)
  } catch let t {
    assertionFailure("Failed to run bytecode with error: \(t)")
  }
}

@_cdecl("runPathBytecode")
public func runPathBytecode(
  _ path: CGMutablePath,
  _ start: UnsafePointer<UInt8>,
  _ len: Int
) {
  do {
    try PathBytecodeRunner.run(path, start, len)
  } catch let t {
    assertionFailure("Failed to run bytecode with error: \(t)")
  }
}

public enum Error: Swift.Error {
  case outOfBounds(left: Int, required: Int)
  case failedToCreateGradient
  case invalidGradientId(id: BCIdType)
  case invalidSubrouteId(id: BCIdType)
}

private func normalize(_ value: UInt8) -> CGFloat {
  CGFloat(value) / CGFloat(UInt8.max)
}

extension BCRGBAColor {
  var norm: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    (normalize(red), normalize(green), normalize(blue), alpha)
  }

  var components: [CGFloat] {
    let norm = self.norm
    return [norm.r, norm.g, norm.b, alpha]
  }
}

extension BCRGBColor {
  var norm: (r: CGFloat, g: CGFloat, b: CGFloat) {
    (normalize(red), normalize(green), normalize(blue))
  }
}

public struct PathBytecodeRunner {
  private var programCounter: Bytecode
  private var exec: PathCommandExecution

  fileprivate init(bytecode: Bytecode, exec: PathCommandExecution) {
    programCounter = bytecode
    self.exec = exec
  }

  static func run(
    _ path: CGMutablePath,
    _ start: UnsafeRawPointer,
    _ len: Int
  ) throws {
    let bytecode = Bytecode(base: start, count: len)
    var runner = PathBytecodeRunner(bytecode: bytecode, exec: .init(path: path))
    try runner.run()
  }

  mutating func run() throws {
    while programCounter.count > 0 {
      let command = try PathCommand(bytecode: &programCounter)
      switch command {
      case .moveTo:
        try exec.moveTo(read())
      case .curveTo:
        try exec.curveTo(read())
      case .lineTo:
        try exec.lineTo(read())
      case .appendRectangle:
        try exec.appendRectangle(read())
      case .appendRoundedRect:
        try exec.appendRoundedRect(read())
      case .addArc:
        try exec.addArc(read())
      case .closePath:
        try exec.closePath(read())
      case .lines:
        try exec.lines(read())
      case .addEllipse:
        try exec.addEllipse(read())
      }
    }
  }

  func read() throws {}

  mutating func read<T: BytecodeDecodable>(_: T.Type = T.self) throws -> T {
    try T(bytecode: &programCounter)
  }

  mutating func read<
    T0: BytecodeDecodable, T1: BytecodeDecodable
  >(
    _: (T0, T1).Type = (T0, T1).self
  ) throws -> (T0, T1) {
    try (
      read(T0.self), read(T1.self)
    )
  }

  mutating func read<
    T0: BytecodeDecodable, T1: BytecodeDecodable, T2: BytecodeDecodable
  >(
    _: (T0, T1, T2).Type = (T0, T1, T2).self
  ) throws -> (T0, T1, T2) {
    try (
      read(T0.self), read(T1.self), read(T2.self)
    )
  }

  mutating func read<
    T0: BytecodeDecodable, T1: BytecodeDecodable, T2: BytecodeDecodable,
    T3: BytecodeDecodable, T4: BytecodeDecodable
  >(
    _: (T0, T1, T2, T3, T4).Type = (T0, T1, T2, T3, T4).self
  ) throws -> (T0, T1, T2, T3, T4) {
    try (
      read(T0.self), read(T1.self), read(T2.self),
      read(T3.self), read(T4.self)
    )
  }

  mutating func readSubroute() throws -> Bytecode {
    let sz = try Int(programCounter.read(type: BCSizeType.self))
    guard sz <= programCounter.count else {
      throw Error.outOfBounds(left: programCounter.count, required: sz)
    }
    return programCounter.advance(count: sz)
  }
}

public struct BytecodeRunner {
  private var programCounter: Bytecode

  private var exec: CommandExecution

  static func run(
    _ context: CGContext,
    _ start: UnsafeRawPointer,
    _ len: Int
  ) throws {
    let bytecode = Bytecode(base: start, count: len)
    let ctx = ExtendedContext(initial: .default, context: context)
    var runner = BytecodeRunner(bytecode: bytecode, executor: .init(ctx: ctx))
    try runner.run()
  }

  fileprivate init(bytecode: Bytecode, executor: CommandExecution) {
    programCounter = bytecode
    exec = executor
  }

  mutating func run() throws {
    // MARK: Reading gradients and subroutes

    let gradientCount: BCIdType = try read()
    for _ in 0..<gradientCount {
      let id: BCIdType = try read()
      exec.gradients[id] = try read(BCGradient.self)
    }

    let subrouteCount: BCIdType = try read()
    for _ in 0..<subrouteCount {
      let id: BCIdType = try read()
      try exec.subroutes[id] = readSubroute()
    }

    exec.ctx.synchronize()

    // MARK: Executing commands

    while programCounter.count > 0 {
      let command = try DrawCommand(bytecode: &programCounter)
      switch command {
      case .addArc:
        try exec.addArc(read())
      case .addEllipse:
        try exec.addEllipse(read())
      case .appendRectangle:
        try exec.appendRectangle(read())
      case .appendRoundedRect:
        try exec.appendRoundedRect(read())
      case .beginTransparencyLayer:
        try exec.beginTransparencyLayer(read())
      case .blendMode:
        try exec.blendMode(read())
      case .clip:
        try exec.clip(read())
      case .clipWithRule:
        try exec.clipWithRule(read())
      case .clipToRect:
        try exec.clipToRect(read())
      case .closePath:
        try exec.closePath(read())
      case .colorRenderingIntent:
        try exec.colorRenderingIntent(read())
      case .concatCTM:
        try exec.concatCTM(read())
      case .curveTo:
        try exec.curveTo(read())
      case .dash:
        try exec.dash(read())
      case .dashPhase:
        try exec.dashPhase(read())
      case .dashLenghts:
        try exec.dashLenghts(read())
      case .drawPath:
        try exec.drawPath(read())
      case .endTransparencyLayer:
        try exec.endTransparencyLayer(read())
      case .fill:
        try exec.fill(read())
      case .fillWithRule:
        try exec.fillWithRule(read())
      case .fillAndStroke:
        try exec.fillAndStroke(read())
      case .fillColor:
        try exec.fillColor(read())
      case .fillRule:
        try exec.fillRule(read())
      case .fillEllipse:
        try exec.fillEllipse(read())
      case .flatness:
        try exec.flatness(read())
      case .globalAlpha:
        try exec.globalAlpha(read())
      case .lineCapStyle:
        try exec.lineCapStyle(read())
      case .lineJoinStyle:
        try exec.lineJoinStyle(read())
      case .lineTo:
        try exec.lineTo(read())
      case .lineWidth:
        try exec.lineWidth(read())
      case .linearGradient:
        try exec.linearGradient(read())
      case .lines:
        try exec.lines(read())
      case .moveTo:
        try exec.moveTo(read())
      case .radialGradient:
        try exec.radialGradient(read())
      case .fillLinearGradient:
        try exec.fillLinearGradient(read())
      case .fillRadialGradient:
        try exec.fillRadialGradient(read())
      case .strokeLinearGradient:
        try exec.strokeLinearGradient(read())
      case .strokeRadialGradient:
        try exec.strokeRadialGradient(read())
      case .replacePathWithStrokePath:
        try exec.replacePathWithStrokePath(read())
      case .restoreGState:
        try exec.restoreGState(read())
      case .saveGState:
        try exec.saveGState(read())
      case .stroke:
        try exec.stroke(read())
      case .strokeColor:
        try exec.strokeColor(read())
      case .subrouteWithId:
        try exec.subrouteWithId(read())
      case .shadow:
        try exec.shadow(read())
      case .strokeAlpha:
        try exec.strokeAlpha(read())
      case .fillAlpha:
        try exec.fillAlpha(read())
      case .strokeNone:
        try exec.strokeNone(read())
      case .fillNone:
        try exec.fillNone(read())
      case .setGlobalAlphaToFillAlpha:
        try exec.setGlobalAlphaToFillAlpha(read())
      }
    }
  }

  func read() throws {}

  mutating func read<T: BytecodeDecodable>(_: T.Type = T.self) throws -> T {
    try T(bytecode: &programCounter)
  }

  mutating func read<
    T0: BytecodeDecodable, T1: BytecodeDecodable
  >(
    _: (T0, T1).Type = (T0, T1).self
  ) throws -> (T0, T1) {
    try (
      read(T0.self), read(T1.self)
    )
  }

  mutating func read<
    T0: BytecodeDecodable, T1: BytecodeDecodable, T2: BytecodeDecodable
  >(
    _: (T0, T1, T2).Type = (T0, T1, T2).self
  ) throws -> (T0, T1, T2) {
    try (
      read(T0.self), read(T1.self), read(T2.self)
    )
  }

  mutating func read<
    T0: BytecodeDecodable, T1: BytecodeDecodable, T2: BytecodeDecodable,
    T3: BytecodeDecodable, T4: BytecodeDecodable
  >(
    _: (T0, T1, T2, T3, T4).Type = (T0, T1, T2, T3, T4).self
  ) throws -> (T0, T1, T2, T3, T4) {
    try (
      read(T0.self), read(T1.self), read(T2.self),
      read(T3.self), read(T4.self)
    )
  }

  mutating func readSubroute() throws -> Bytecode {
    let sz = try Int(programCounter.read(type: BCSizeType.self))
    guard sz <= programCounter.count else {
      throw Error.outOfBounds(left: programCounter.count, required: sz)
    }
    return programCounter.advance(count: sz)
  }
}

private struct GState {
  struct DashPattern {
    var phase: CGFloat
    var lengths: [CGFloat]?

    init(phase: CGFloat, lengths: [CGFloat]? = nil) {
      self.phase = phase
      self.lengths = lengths
    }

    init(_ bcdash: BCDashPattern) {
      phase = bcdash.phase
      lengths = bcdash.lengths
    }
  }

  enum Dye {
    enum GradientType {
      case linear(BCLinearGradientDrawingOptions)
      case radial(BCRadialGradientDrawingOptions)
    }

    typealias Gradient = (CGGradient, type: GradientType)

    case color(BCRGBColor)
    case gradient(Gradient)
  }

  struct Paint {
    var dye: Dye?
    var alpha: CGFloat

    init(dye: Dye? = nil, alpha: CGFloat) {
      self.dye = dye
      self.alpha = alpha
    }

    init(color: BCRGBColor, alpha: CGFloat) {
      dye = .color(color)
      self.alpha = alpha
    }

    static let black = Self(color: .init(r: 0, g: 0, b: 0), alpha: 1)
    static let none = Self(dye: nil, alpha: 1)
  }

  var fillRule: BCFillRule
  var fill: Paint
  var stroke: Paint
  var dash: DashPattern
  var fillColorSpace: CGColorSpace

  static let `default` = Self(
    fillRule: .winding,
    fill: .black, stroke: .none,
    dash: .init(phase: 0, lengths: nil),
    fillColorSpace: CGColorSpaceCreateDeviceRGB()
  )
}

private struct CommandExecution {
  var subroutes: [BCIdType: Bytecode] = [:]
  var gradients: [BCIdType: BCGradient] = [:]

  var ctx: ExtendedContext
  var cg: CGContext { ctx.cg }

  func getGradient(id: BCIdType) throws -> CGGradient {
    guard let gradient = gradients[id] else {
      throw Error.invalidGradientId(id: id)
    }
    return try .make(gradient, colorSpace: ctx.fillColorSpace)
  }

  func moveTo(_ args: DrawCommand.MoveToArgs) {
    cg.move(to: args)
  }

  func curveTo(_ args: DrawCommand.CurveToArgs) {
    cg.addCurve(
      to: args.to,
      control1: args.control1,
      control2: args.control2
    )
  }

  func lineTo(_ args: DrawCommand.LineToArgs) {
    cg.addLine(to: args)
  }

  func appendRectangle(_ args: DrawCommand.AppendRectangleArgs) {
    cg.addRect(args)
  }

  func appendRoundedRect(_ args: DrawCommand.AppendRoundedRectArgs) {
    let path = CGPath(
      roundedRect: args.0,
      cornerWidth: args.rx,
      cornerHeight: args.ry,
      transform: nil
    )
    cg.addPath(path)
  }

  func addArc(_ args: DrawCommand.AddArcArgs) {
    cg.addArc(
      center: args.center,
      radius: args.radius,
      startAngle: args.startAngle,
      endAngle: args.endAngle,
      clockwise: args.clockwise
    )
  }

  func lines(_ args: DrawCommand.LinesArgs) {
    cg.addLines(between: args)
  }

  func clipWithRule(_ args: DrawCommand.ClipWithRuleArgs) {
    cg.clip(using: .init(args))
  }

  func clipToRect(_ args: DrawCommand.ClipToRectArgs) {
    cg.clip(to: args)
  }

  mutating func dash(_ args: DrawCommand.DashArgs) {
    ctx.dash = .init(args)
    cg.setDash(ctx.dash)
  }

  mutating func dashPhase(_ args: DrawCommand.DashPhaseArgs) {
    ctx.dash.phase = args
    cg.setDash(ctx.dash)
  }

  mutating func dashLenghts(_ args: DrawCommand.DashLenghtsArgs) {
    ctx.dash.lengths = args
    cg.setDash(ctx.dash)
  }

  func fillWithRule(_ args: DrawCommand.FillWithRuleArgs) {
    cg.fillPath(using: .init(args))
  }

  func fillEllipse(_ args: DrawCommand.FillEllipseArgs) {
    cg.fillEllipse(in: args)
  }

  func drawPath(_ args: DrawCommand.DrawPathArgs) {
    cg.drawPath(using: args)
  }

  func addEllipse(_ args: DrawCommand.AddEllipseArgs) {
    cg.addEllipse(in: args)
  }

  func concatCTM(_ args: DrawCommand.ConcatCTMArgs) {
    cg.concatenate(args)
  }

  func flatness(_ args: DrawCommand.FlatnessArgs) {
    cg.setFlatness(args)
  }

  func lineWidth(_ args: DrawCommand.LineWidthArgs) {
    cg.setLineWidth(args)
  }

  func lineJoinStyle(_ args: DrawCommand.LineJoinStyleArgs) {
    cg.setLineJoin(args)
  }

  func lineCapStyle(_ args: DrawCommand.LineCapStyleArgs) {
    cg.setLineCap(args)
  }

  func colorRenderingIntent(_ args: DrawCommand.ColorRenderingIntentArgs) {
    cg.setRenderingIntent(args)
  }

  func globalAlpha(_ args: DrawCommand.GlobalAlphaArgs) {
    cg.setAlpha(args)
  }

  mutating func strokeColor(_ args: DrawCommand.StrokeColorArgs) {
    ctx.setStrokeColor(args)
  }

  mutating func strokeAlpha(_ args: DrawCommand.StrokeAlphaArgs) {
    ctx.setStrokeAlpha(args)
  }

  mutating func fillColor(_ args: DrawCommand.FillColorArgs) {
    ctx.setFillColor(args)
  }

  mutating func fillAlpha(_ args: DrawCommand.FillAlphaArgs) {
    ctx.setFillAlpha(args)
  }

  mutating func fillRule(_ args: DrawCommand.FillRuleArgs) {
    ctx.fillRule = args
  }

  func linearGradient(_ args: DrawCommand.LinearGradientArgs) throws {
    try ctx.drawLinearGradient(
      getGradient(id: args.id),
      options: args.1
    )
  }

  func radialGradient(_ args: DrawCommand.RadialGradientArgs) throws {
    try ctx.drawRadialGradient(
      getGradient(id: args.id), options: args.1
    )
  }

  mutating func fillLinearGradient(
    _ args: DrawCommand.FillLinearGradientArgs
  ) throws {
    try ctx.fill.dye = .gradient((
      getGradient(id: args.id),
      .linear(args.1)
    ))
  }

  mutating func fillRadialGradient(
    _ args: DrawCommand.FillRadialGradientArgs
  ) throws {
    try ctx.fill.dye = .gradient((
      getGradient(id: args.id),
      .radial(args.1)
    ))
  }

  mutating func strokeLinearGradient(
    _ args: DrawCommand.StrokeLinearGradientArgs
  ) throws {
    try ctx.stroke.dye = .gradient((
      getGradient(id: args.id),
      .linear(args.1)
    ))
  }

  mutating func strokeRadialGradient(
    _ args: DrawCommand.StrokeRadialGradientArgs
  ) throws {
    try ctx.stroke.dye = .gradient((
      getGradient(id: args.id),
      .radial(args.1)
    ))
  }

  func subrouteWithId(_ args: DrawCommand.SubrouteWithIdArgs) throws {
    guard let subroute = subroutes[args] else {
      throw Error.invalidSubrouteId(id: args)
    }
    var runner = BytecodeRunner(bytecode: subroute, executor: .init(ctx: ctx))
    try runner.run()
  }

  mutating func shadow(_ args: DrawCommand.ShadowArgs) {
    ctx.drawShadow(args)
  }

  func blendMode(_ args: DrawCommand.BlendModeArgs) {
    _ = args
    cg.setBlendMode(args)
  }

  mutating func saveGState(_ args: DrawCommand.SaveGStateArgs) {
    _ = args
    ctx.saveGState()
  }

  mutating func restoreGState(_ args: DrawCommand.RestoreGStateArgs) {
    _ = args
    ctx.restoreGState()
  }

  func closePath(_ args: DrawCommand.ClosePathArgs) {
    _ = args
    cg.closePath()
  }

  func replacePathWithStrokePath(
    _ args: DrawCommand.ReplacePathWithStrokePathArgs
  ) {
    _ = args
    cg.replacePathWithStrokedPath()
  }

  func clip(_ args: DrawCommand.ClipArgs) {
    _ = args
    ctx.clip()
  }

  func fill(_ args: DrawCommand.FillArgs) {
    _ = args
    cg.fillPath(using: .init(ctx.fillRule))
  }

  func stroke(_ args: DrawCommand.StrokeArgs) {
    _ = args
    cg.strokePath()
  }

  func fillAndStroke(_ args: DrawCommand.FillAndStrokeArgs) throws {
    _ = args
    try ctx.fillAndStroke()
  }

  func setGlobalAlphaToFillAlpha(
    _ args: DrawCommand.SetGlobalAlphaToFillAlphaArgs
  ) {
    _ = args
    cg.setAlpha(ctx.fill.alpha)
  }

  mutating func strokeNone(_ args: DrawCommand.StrokeNoneArgs) {
    _ = args
    ctx.stroke.dye = nil
  }

  mutating func fillNone(_ args: DrawCommand.FillNoneArgs) {
    _ = args
    ctx.fill.dye = nil
  }

  func beginTransparencyLayer(_ args: DrawCommand.BeginTransparencyLayerArgs) {
    _ = args
    cg.beginTransparencyLayer(auxiliaryInfo: nil)
  }

  func endTransparencyLayer(_ args: DrawCommand.EndTransparencyLayerArgs) {
    _ = args
    cg.endTransparencyLayer()
  }
}

private struct PathCommandExecution {
  var path: CGMutablePath

  func moveTo(_ args: PathCommand.MoveToArgs) {
    path.move(to: args)
  }

  func curveTo(_ args: PathCommand.CurveToArgs) {
    path.addCurve(
      to: args.to,
      control1: args.control1,
      control2: args.control2
    )
  }

  func lineTo(_ args: PathCommand.LineToArgs) {
    path.addLine(to: args)
  }

  func appendRectangle(_ args: PathCommand.AppendRectangleArgs) {
    path.addRect(args)
  }

  func appendRoundedRect(_ args: PathCommand.AppendRoundedRectArgs) {
    path.addRoundedRect(in: args.0, cornerWidth: args.rx, cornerHeight: args.ry)
  }

  func addArc(_ args: PathCommand.AddArcArgs) {
    path.addArc(
      center: args.center,
      radius: args.radius,
      startAngle: args.startAngle,
      endAngle: args.endAngle,
      clockwise: args.clockwise
    )
  }

  func lines(_ args: PathCommand.LinesArgs) {
    path.addLines(between: args)
  }

  func addEllipse(_ args: PathCommand.AddEllipseArgs) {
    path.addEllipse(in: args)
  }

  func closePath(_ args: PathCommand.ClosePathArgs) {
    _ = args
    path.closeSubpath()
  }
}

@dynamicMemberLookup
private struct ExtendedContext {
  private var gstateStack: [GState]
  var gstate: GState
  private(set) var cg: CGContext

  init(initial: GState, context: CGContext) {
    gstateStack = []
    gstate = initial
    cg = context
  }

  mutating func saveGState() {
    gstateStack.append(gstate)
    cg.saveGState()
  }

  mutating func restoreGState() {
    if let saved = gstateStack.popLast() {
      gstate = saved
    }
    cg.restoreGState()
  }

  subscript<T>(dynamicMember kp: WritableKeyPath<GState, T>) -> T {
    get { gstate[keyPath: kp] }
    set { gstate[keyPath: kp] = newValue }
  }

  func synchronize() {
    cg.setFillColorSpace(gstate.fillColorSpace)
    cg.setStrokeColorSpace(gstate.fillColorSpace)
  }

  func clip() {
    cg.clip(using: .init(gstate.fillRule))
  }

  mutating func setFillColor(_ c: BCRGBColor) {
    gstate.fill.dye = .color(c)
    syncFillDye()
  }

  mutating func setFillAlpha(_ alpha: CGFloat) {
    gstate.fill.alpha = alpha
    syncFillDye()
  }

  mutating func setStrokeColor(_ c: BCRGBColor) {
    gstate.stroke.dye = .color(c)
    syncStrokeDye()
  }

  mutating func setStrokeAlpha(_ alpha: CGFloat) {
    gstate.stroke.alpha = alpha
    syncStrokeDye()
  }

  private func syncFillDye() {
    let paint = gstate.fill
    switch paint.dye {
    case let .color(color):
      cg.setFillColor(color, alpha: paint.alpha)
    case .gradient, nil:
      cg.setFillColor(CGColor(
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        components: [0, 0, 0, 0]
      )!)
    }
  }

  private func syncStrokeDye() {
    let paint = gstate.stroke
    switch paint.dye {
    case let .color(color):
      cg.setStrokeColor(color, alpha: paint.alpha)
    case .gradient, nil:
      cg.setStrokeColor(CGColor(
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        components: [0, 0, 0, 0]
      )!)
    }
  }

  fileprivate func fillAndStroke() throws {
    switch (gstate.stroke.dye, gstate.fill.dye) {
    case (.color, .color):
      switch gstate.fillRule {
      case .winding:
        cg.drawPath(using: .fillStroke)
      case .evenOdd:
        cg.drawPath(using: .eoFillStroke)
      }
    case (nil, .color):
      switch gstate.fillRule {
      case .winding:
        cg.drawPath(using: .fill)
      case .evenOdd:
        cg.drawPath(using: .eoFill)
      }
    case (.color, nil):
      cg.drawPath(using: .stroke)
    case let (.gradient(stroke), .gradient(fill)):
      guard let path = cg.path else { return }
      fillWithGradient(fill)
      strokeWithGradient(stroke, path: path)
    case let (.gradient(stroke), .color):
      guard let path = cg.path else { return }
      cg.fillPath(using: .init(gstate.fillRule))
      strokeWithGradient(stroke, path: path)
    case let (.color, .gradient(fill)):
      guard let path = cg.path else { return }
      fillWithGradient(fill)
      cg.addPath(path)
      cg.strokePath()
    case let (.gradient(stroke), nil):
      strokeWithGradient(stroke)
    case let (nil, .gradient(fill)):
      fillWithGradient(fill)
    case (nil, nil):
      cg.beginPath()
    }
  }

  fileprivate func fillWithGradient(
    _ gradient: GState.Dye.Gradient,
    path: CGPath? = nil
  ) {
    cg.savingGState {
      if let path = path {
        cg.beginPath()
        cg.addPath(path)
      }
      clip()
      cg.setAlpha(gstate.fill.alpha)
      drawGradient(gradient)
    }
  }

  fileprivate func strokeWithGradient(
    _ gradient: GState.Dye.Gradient,
    path: CGPath? = nil
  ) {
    cg.savingGState {
      if let path = path {
        cg.beginPath()
        cg.addPath(path)
      }
      cg.replacePathWithStrokedPath()
      clip()
      cg.setAlpha(gstate.stroke.alpha)
      drawGradient(gradient)
    }
  }

  func drawGradient(_ gradient: GState.Dye.Gradient) {
    switch gradient.1 {
    case let .linear(options):
      drawLinearGradient(gradient.0, options: options)
    case let .radial(options):
      drawRadialGradient(gradient.0, options: options)
    }
  }

  func drawLinearGradient(
    _ gradient: CGGradient,
    options: BCLinearGradientDrawingOptions
  ) {
    cg.drawLinearGradient(
      gradient,
      start: options.start,
      end: options.end,
      options: options.options
    )
  }

  func drawRadialGradient(
    _ gradient: CGGradient,
    options: BCRadialGradientDrawingOptions
  ) {
    cg.drawRadialGradient(
      gradient,
      startCenter: options.startCenter,
      startRadius: options.startRadius,
      endCenter: options.endCenter,
      endRadius: options.endRadius,
      options: options.drawingOptions
    )
  }

  mutating func drawShadow(_ shadow: BCShadow) {
    let ctm = cg.ctm
    let cs = gstate.fillColorSpace
    let a = ctm.a
    let c = ctm.c
    let scaleX = sqrt(a * a + c * c)
    let offset = shadow.offset.applying(ctm)
    let blur = floor(shadow.blur * scaleX + 0.5)
    let color = CGColor(colorSpace: cs, components: shadow.color.components)
    cg.setShadow(offset: offset, blur: blur, color: color)
  }
}

extension CGContext {
  fileprivate func setFillColor(_ rgb: BCRGBColor, alpha: CGFloat) {
    let rgb = rgb.norm
    setFillColor(
      red: rgb.r, green: rgb.g, blue: rgb.b, alpha: alpha
    )
  }

  fileprivate func setStrokeColor(_ rgb: BCRGBColor, alpha: CGFloat) {
    let rgb = rgb.norm
    setStrokeColor(
      red: rgb.r, green: rgb.g, blue: rgb.b, alpha: alpha
    )
  }

  fileprivate func setDash(_ dash: GState.DashPattern) {
    guard let lenghts = dash.lengths else { return }
    setLineDash(phase: dash.phase, lengths: lenghts)
  }

  fileprivate func savingGState<T>(_ code: () throws -> T) rethrows -> T {
    saveGState()
    defer {
      restoreGState()
    }
    return try code()
  }
}

extension CGPathFillRule {
  init(_ bc: BCFillRule) {
    switch bc {
    case .winding:
      self = .winding
    case .evenOdd:
      self = .evenOdd
    }
  }
}

extension CGGradient {
  static func make(
    _ bc: BCGradient,
    colorSpace cs: CGColorSpace
  ) throws -> CGGradient {
    let sz = bc.count
    let colors = bc.flatMap(\.color.components)
    let locations = bc.map(\.location)
    guard let gradient = CGGradient(
      colorSpace: cs,
      colorComponents: colors,
      locations: locations,
      count: sz
    ) else {
      throw Error.failedToCreateGradient
    }
    return gradient
  }
}

private func decompressBytecode(
  _ start: UnsafePointer<UInt8>,
  _ compressedLen: Int,
  _ decompressedLen: Int
) throws -> [UInt8] {
  let decodedDestinationBuffer = UnsafeMutablePointer<UInt8>
    .allocate(capacity: decompressedLen)

  let decompressedSize = compression_decode_buffer(
    decodedDestinationBuffer,
    decompressedLen,
    start,
    compressedLen,
    nil,
    COMPRESSION_LZFSE
  )

  return [UInt8](UnsafeBufferPointer(
    start: decodedDestinationBuffer,
    count: decompressedSize
  ))
}

private final class Cache<Value> {
  class WrappedValue {
    let value: Value

    init(_ value: Value) { self.value = value }
  }

  private let cache = NSCache<NSNumber, WrappedValue>()

  subscript(key: UnsafePointer<UInt8>) -> Value? {
    get {
      cache.object(forKey: NSNumber(pointer: key))?.value
    }
    set {
      if let newValue {
        cache.setObject(WrappedValue(newValue), forKey: NSNumber(pointer: key))
      } else {
        cache.removeObject(forKey: NSNumber(pointer: key))
      }
    }
  }
}

private let cache = Cache<[UInt8]>()
