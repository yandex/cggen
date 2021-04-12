import CoreGraphics
import Foundation

import BCCommon

extension BCRGBAColor {
  var components: [CGFloat] { [red, green, blue, alpha] }
}

class BytecodeRunner {
  enum Error: Swift.Error {
    case outOfBounds(left: BCSizeType, required: BCSizeType)
    case failedToCreateGradient
    case invalidGradientId
    case invalidSubrouteId
  }

  struct State {
    var position: UnsafePointer<UInt8>
    var remaining: BCSizeType
  }

  class Commons {
    var subroutes: [BCIdType: State] = [:]
    var gradients: [BCIdType: CGGradient] = [:]
    let context: CGContext
    let cs: CGColorSpace
    init(_ context: CGContext, _ cs: CGColorSpace) {
      self.cs = cs
      self.context = context
    }
  }

  var currentState: State
  let commons: Commons
  init(_ state: State, _ commons: Commons) {
    currentState = state
    self.commons = commons
  }

  func advance(_ count: BCSizeType) {
    currentState.position += Int(count)
    currentState.remaining -= count
  }

  func readInt<T: FixedWidthInteger>(_: T.Type = T.self) throws -> T {
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

  func read<T: BytecodeElement>(_: T.Type = T.self) throws -> T {
    try T.readFrom(self)
  }

  func drawLinearGradient(_ gradient: CGGradient) throws {
    let context = commons.context
    let options: BCLinearGradientDrawingOptions = try read()
    context.drawLinearGradient(
      gradient,
      start: options.start,
      end: options.end,
      options: options.options
    )
  }

  func drawRadialGradient(_ gradient: CGGradient) throws {
    let context = commons.context
    let options: BCRadialGradientDrawingOptions = try read()
    context.drawRadialGradient(
      gradient,
      startCenter: options.startCenter,
      startRadius: options.startRadius,
      endCenter: options.endCenter,
      endRadius: options.endRadius,
      options: options.drawingOptions
    )
  }

  func readGradient() throws -> CGGradient {
    let gradientDesc: BCGradient = try read()
    let sz = gradientDesc.count
    let cs = commons.cs
    let colors = gradientDesc.flatMap(\.color.components)
    let locations = gradientDesc.map(\.location)
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

  func readSubroute() throws -> State {
    let sz: BCSizeType = try read()
    guard sz <= currentState.remaining else {
      throw Error.outOfBounds(left: currentState.remaining, required: sz)
    }
    let subroute = State(position: currentState.position, remaining: sz)
    advance(sz)
    return subroute
  }

  func drawShadow() throws {
    let context = commons.context
    let shadow: BCShadow = try read()
    let ctm = context.ctm
    let cs = commons.cs
    let a = ctm.a
    let c = ctm.c
    let scaleX = sqrt(a * a + c * c)
    let offset = shadow.offset.applying(ctm)
    let blur = floor(shadow.blur * scaleX + 0.5)
    let color = CGColor(colorSpace: cs, components: shadow.color.components)
    context.setShadow(offset: offset, blur: blur, color: color)
  }

  func run() throws {
    let context = commons.context

    // MARK: Reading gradients and subroutes

    let gradientCount: BCIdType = try read()
    for _ in 0..<gradientCount {
      let id: BCIdType = try read()
      commons.gradients[id] = try readGradient()
    }

    let subrouteCount: BCIdType = try read()
    for _ in 0..<subrouteCount {
      let id: BCIdType = try read()
      try commons.subroutes[id] = readSubroute()
    }

    // MARK: Executing commands

    while currentState.remaining > 0 {
      let command: Command = try read()
      switch command {
      case .addArc:
        try context.addArc(
          center: read(),
          radius: read(),
          startAngle: read(),
          endAngle: read(),
          clockwise: read()
        )
      case .addEllipse:
        try context.addEllipse(in: read())
      case .appendRectangle:
        try context.addRect(read())
      case .appendRoundedRect:
        let path = try CGPath(
          roundedRect: read(),
          cornerWidth: read(),
          cornerHeight: read(),
          transform: nil
        )
        context.addPath(path)
      case .beginTransparencyLayer:
        context.beginTransparencyLayer(auxiliaryInfo: nil)
      case .blendMode:
        try context.setBlendMode(read())
      case .clip:
        try context.clip(using: read())
      case .clipToRect:
        try context.clip(to: read(CGRect.self))
      case .closePath:
        context.closePath()
      case .colorRenderingIntent:
        try context.setRenderingIntent(read())
      case .concatCTM:
        try context.concatenate(read())
      case .curveTo:
        let curve: BCCubicCurve = try read()
        context.addCurve(
          to: curve.to,
          control1: curve.control1,
          control2: curve.control2
        )
      case .dash:
        let dashPattern: BCDashPattern = try read()
        context.setLineDash(
          phase: dashPattern.phase,
          lengths: dashPattern.lengths
        )
      case .drawPath:
        try context.drawPath(using: read())
      case .endTransparencyLayer:
        context.endTransparencyLayer()
      case .fill:
        try context.fillPath(using: read())
      case .fillColor:
        let color: BCRGBAColor = try read()
        context.setFillColor(color.components)
      case .fillEllipse:
        try context.fillEllipse(in: read())
      case .flatness:
        try context.setFlatness(read())
      case .globalAlpha:
        try context.setAlpha(read())
      case .lineCapStyle:
        try context.setLineCap(read())
      case .lineJoinStyle:
        try context.setLineJoin(read())
      case .lineTo:
        try context.addLine(to: read())
      case .lineWidth:
        try context.setLineWidth(read())
      case .linearGradient:
        let id: BCIdType = try read()
        guard let gradient = commons.gradients[id] else {
          throw Error.invalidGradientId
        }
        try drawLinearGradient(gradient)
      case .linearGradientInlined:
        let gradient = try readGradient()
        try drawLinearGradient(gradient)
      case .lines:
        try context.addLines(between: read())
      case .moveTo:
        try context.move(to: read())
      case .radialGradient:
        let id: BCIdType = try read()
        guard let gradient = commons.gradients[id] else {
          throw Error.invalidGradientId
        }
        try drawRadialGradient(gradient)
      case .radialGradientInlined:
        let gradient = try readGradient()
        try drawRadialGradient(gradient)
      case .replacePathWithStrokePath:
        context.replacePathWithStrokedPath()
      case .restoreGState:
        context.restoreGState()
      case .saveGState:
        context.saveGState()
      case .stroke:
        context.strokePath()
      case .strokeColor:
        let color: BCRGBAColor = try read()
        context.setStrokeColor(color.components)
      case .subrouteWithId:
        let id: BCIdType = try read()
        guard let subroute = commons.subroutes[id] else {
          throw Error.invalidSubrouteId
        }
        try BytecodeRunner(subroute, commons).run()
      case .shadow:
        try drawShadow()
      }
    }
  }
}

public func runBytecode(_ context: CGContext, fromData data: Data) throws {
  let sz = data.count
  try data.withUnsafeBytes {
    let ptr = $0.bindMemory(to: UInt8.self).baseAddress!
    try runBytecodeThrowing(context, ptr, sz)
  }
}

func runBytecodeThrowing(
  _ context: CGContext,
  _ start: UnsafePointer<UInt8>,
  _ len: Int
) throws {
  let cs = CGColorSpaceCreateDeviceRGB()
  context.setFillColorSpace(cs)
  context.setStrokeColorSpace(cs)
  let state = BytecodeRunner.State(position: start, remaining: BCSizeType(len))
  let commons = BytecodeRunner.Commons(context, cs)
  try BytecodeRunner(state, commons).run()
}

@_cdecl("runBytecode") func runBytecode(
  _ context: CGContext,
  _ start: UnsafePointer<UInt8>,
  _ len: Int
) {
  try! runBytecodeThrowing(context, start, len)
}
