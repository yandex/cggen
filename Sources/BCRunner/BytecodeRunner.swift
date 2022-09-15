import CoreGraphics
import Foundation

import BCCommon

public func runBytecode(_ context: CGContext, fromData data: Data) throws {
  let sz = data.count
  try data.withUnsafeBytes {
    let ptr = $0.bindMemory(to: UInt8.self).baseAddress!
    try BytecodeRunner.run(context, ptr, sz)
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

public enum Error: Swift.Error {
  case outOfBounds(left: BCSizeType, required: BCSizeType)
  case failedToCreateGradient
  case invalidGradientId(id: BCIdType)
  case invalidSubrouteId(id: BCIdType)
}

extension BCRGBAColor {
  var components: [CGFloat] { [red, green, blue, alpha] }
}

public struct BytecodeRunner {
  struct State {
    var position: UnsafePointer<UInt8>
    var remaining: BCSizeType
  }

  private struct Commons {
    var subroutes: [BCIdType: State] = [:]
    var gradients: [BCIdType: BCGradient] = [:]
    var context: ExtendedContext

    init(_ context: ExtendedContext) {
      self.context = context
    }
  }

  private var currentState: State
  private var commons: Commons
  
  private var context: ExtendedContext {
    get { commons.context }
    set { commons.context = newValue }
  }
  private var cgcontext: CGContext { context.cg }
  
  static func run(
    _ context: CGContext,
    _ start: UnsafePointer<UInt8>,
    _ len: Int
  ) throws {
    let state = BytecodeRunner.State(position: start, remaining: BCSizeType(len))
    let commons = BytecodeRunner.Commons(
      ExtendedContext(initial: .default, context: context)
    )
    var runner = BytecodeRunner(state, commons, gstate: .default)
    try runner.run()
  }

  private init(_ state: State, _ commons: Commons, gstate: GState) {
    currentState = state
    self.commons = commons
  }

  mutating func run() throws {
    // MARK: Reading gradients and subroutes

    let gradientCount: BCIdType = try read()
    for _ in 0..<gradientCount {
      let id: BCIdType = try read()
      commons.gradients[id] = try read(BCGradient.self)
    }

    let subrouteCount: BCIdType = try read()
    for _ in 0..<subrouteCount {
      let id: BCIdType = try read()
      try commons.subroutes[id] = readSubroute()
    }
    
    context.synchronize()

    // MARK: Executing commands

    while currentState.remaining > 0 {
      let command: Command = try read()
      switch command {
      case .addArc:
        try cgcontext.addArc(
          center: read(),
          radius: read(),
          startAngle: read(),
          endAngle: read(),
          clockwise: read()
        )
      case .addEllipse:
        try cgcontext.addEllipse(in: read())
      case .appendRectangle:
        try cgcontext.addRect(read())
      case .appendRoundedRect:
        let path = try CGPath(
          roundedRect: read(),
          cornerWidth: read(),
          cornerHeight: read(),
          transform: nil
        )
        cgcontext.addPath(path)
      case .beginTransparencyLayer:
        cgcontext.beginTransparencyLayer(auxiliaryInfo: nil)
      case .blendMode:
        try cgcontext.setBlendMode(read())
      case .clip:
        context.clip()
      case .clipWithRule:
        try cgcontext.clip(using: .init(read(BCFillRule.self)))
      case .clipToRect:
        try cgcontext.clip(to: read(CGRect.self))
      case .closePath:
        cgcontext.closePath()
      case .colorRenderingIntent:
        try cgcontext.setRenderingIntent(read())
      case .concatCTM:
        try cgcontext.concatenate(read())
      case .curveTo:
        let curve: BCCubicCurve = try read()
        cgcontext.addCurve(
          to: curve.to,
          control1: curve.control1,
          control2: curve.control2
        )
      case .dash:
        context.dash = try .init(read())
        cgcontext.setDash(context.dash)
      case .dashPhase:
        context.dash.phase = try read()
        cgcontext.setDash(context.dash)
      case .dashLenghts:
        context.dash.lengths = try read()
        cgcontext.setDash(context.dash)
      case .drawPath:
        try cgcontext.drawPath(using: read())
      case .endTransparencyLayer:
        cgcontext.endTransparencyLayer()
      case .fill:
        cgcontext.fillPath(using: .init(context.fillRule))
      case .fillWithRule:
        try cgcontext.fillPath(using: .init(read(BCFillRule.self)))
      case .fillAndStroke:
        try context.fillAndStroke()
      case .fillColor:
        let color = try read(BCRGBColor.self)
        context.setFillColor(color)
      case .fillRule:
        let rule: BCFillRule = try read()
        context.fillRule = rule
      case .fillEllipse:
        try cgcontext.fillEllipse(in: read())
      case .flatness:
        try cgcontext.setFlatness(read())
      case .globalAlpha:
        try cgcontext.setAlpha(read())
      case .lineCapStyle:
        try cgcontext.setLineCap(read())
      case .lineJoinStyle:
        try cgcontext.setLineJoin(read())
      case .lineTo:
        try cgcontext.addLine(to: read())
      case .lineWidth:
        try cgcontext.setLineWidth(read())
      case .linearGradient:
        try context.drawLinearGradient(
          getGradient(id: read()),
          options: read(BCLinearGradientDrawingOptions.self)
        )
      case .lines:
        try cgcontext.addLines(between: read())
      case .moveTo:
        try cgcontext.move(to: read())
      case .radialGradient:
        let gradient = try getGradient(id: read())
        try context.drawRadialGradient(gradient, options: read())
      case .fillLinearGradient:
        try context.fill.dye = .gradient((
          getGradient(id: read()),
          .linear(read())
        ))
      case .fillRadialGradient:
        try context.fill.dye = .gradient((
          getGradient(id: read()),
          .radial(read())
        ))
      case .strokeLinearGradient:
        try context.stroke.dye = .gradient((
          getGradient(id: read()),
          .linear(read())
        ))
      case .strokeRadialGradient:
        try context.stroke.dye = .gradient((
          getGradient(id: read()),
          .radial(read())
        ))
      case .replacePathWithStrokePath:
        cgcontext.replacePathWithStrokedPath()
      case .restoreGState:
        context.restoreGState()
      case .saveGState:
        context.saveGState()
      case .stroke:
        cgcontext.strokePath()
      case .strokeColor:
        try context.setStrokeColor(read())
      case .subrouteWithId:
        let id: BCIdType = try read()
        guard let subroute = commons.subroutes[id] else {
          throw Error.invalidSubrouteId(id: id)
        }
        var runner = BytecodeRunner(subroute, commons, gstate: context.gstate)
        try runner.run()
      case .shadow:
        try context.drawShadow(read(BCShadow.self))
      case .strokeAlpha:
        try context.setStrokeAlpha(read())
      case .fillAlpha:
        try context.setFillAlpha(read())
      case .strokeNone:
        context.stroke.dye = nil
      case .fillNone:
        context.fill.dye = nil
      case .setGlobalAlphaToFillAlpha:
        cgcontext.setAlpha(context.fill.alpha)
      }
    }
  }
  
  mutating func advance(_ count: BCSizeType) {
    currentState.position += Int(count)
    currentState.remaining -= count
  }

  mutating func readInt<T: FixedWidthInteger>(_: T.Type = T.self) throws -> T {
    let size = MemoryLayout<T>.size
    guard size <= currentState.remaining else {
      throw Error.outOfBounds(
        left: currentState.remaining,
        required: UInt32(size)
      )
    }
    var ret: T = 0
    memcpy(&ret, currentState.position, size)
    advance(BCSizeType(size))
    return T(littleEndian: ret)
  }

  mutating func read<T: BytecodeElement>(_: T.Type = T.self) throws -> T {
    try T.readFrom(&self)
  }

  mutating func readSubroute() throws -> State {
    let sz: BCSizeType = try read()
    guard sz <= currentState.remaining else {
      throw Error.outOfBounds(left: currentState.remaining, required: sz)
    }
    let subroute = State(position: currentState.position, remaining: sz)
    advance(sz)
    return subroute
  }
  
  func getGradient(id: BCIdType) throws -> CGGradient {
    guard let gradient = commons.gradients[id] else {
      throw Error.invalidGradientId(id: id)
    }
    return try .make(gradient, colorSpace: context.fillColorSpace)
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
      self.phase = bcdash.phase
      self.lengths = bcdash.lengths
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
      self.dye = .color(color)
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
      cg.setFillColor(.clear)
    }
  }
  
  private func syncStrokeDye() {
    let paint = gstate.stroke
    switch paint.dye {
    case let .color(color):
      cg.setStrokeColor(color, alpha: paint.alpha)
    case .gradient, nil:
      cg.setStrokeColor(.clear)
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
    setFillColor(
      red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: alpha
    )
  }

  fileprivate func setStrokeColor(_ rgb: BCRGBColor, alpha: CGFloat) {
    setStrokeColor(
      red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: alpha
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
