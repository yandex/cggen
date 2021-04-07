import CoreGraphics
import Foundation

import BCCommon

extension BCRGBAColor {
  var components: [CGFloat] { [red, green, blue, alpha] }
}

class BytecodeRunner {
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

  func readInt<T: FixedWidthInteger>(_: T.Type = T.self) -> T {
    let size = MemoryLayout<T>.size
    precondition(size <= currentState.remaining)
    var ret: T = 0
    memcpy(&ret, currentState.position, size)
    advance(BCSizeType(size))
    return T(littleEndian: ret)
  }

  func read<T: BytecodeElement>(_: T.Type = T.self) -> T {
    T.readFrom(self)
  }

  func drawLinearGradient(_ gradient: CGGradient) {
    let context = commons.context
    let options: BCLinearGradientDrawingOptions = read()
    context.drawLinearGradient(
      gradient,
      start: options.start,
      end: options.end,
      options: options.options
    )
  }

  func drawRadialGradient(_ gradient: CGGradient) {
    let context = commons.context
    let options: BCRadialGradientDrawingOptions = read()
    context.drawRadialGradient(
      gradient,
      startCenter: options.startCenter,
      startRadius: options.startRadius,
      endCenter: options.endCenter,
      endRadius: options.endRadius,
      options: options.drawingOptions
    )
  }

  func readGradient() -> CGGradient {
    let gradientDesc: BCGradient = read()
    let sz = gradientDesc.count
    let cs = commons.cs
    let colors = gradientDesc.flatMap(\.color.components)
    let locations = gradientDesc.map(\.location)
    return CGGradient(
      colorSpace: cs,
      colorComponents: colors,
      locations: locations,
      count: sz
    )!
  }

  func readSubroute() -> State {
    let sz: BCSizeType = read()
    precondition(sz <= currentState.remaining)
    let subroute = State(position: currentState.position, remaining: sz)
    advance(sz)
    return subroute
  }

  func drawShadow() {
    let context = commons.context
    let shadow: BCShadow = read()
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

  func run() {
    let context = commons.context

    // MARK: Reading gradients and subroutes

    let gradientCount: BCIdType = read()
    for _ in 0..<gradientCount {
      let id: BCIdType = read()
      commons.gradients[id] = readGradient()
    }

    let subrouteCount: BCIdType = read()
    for _ in 0..<subrouteCount {
      let id: BCIdType = read()
      commons.subroutes[id] = readSubroute()
    }

    // MARK: Executing commands

    while currentState.remaining > 0 {
      let command: Command = read()
      switch command {
      case .addArc:
        context.addArc(
          center: read(),
          radius: read(),
          startAngle: read(),
          endAngle: read(),
          clockwise: read()
        )
      case .addEllipse:
        context.addEllipse(in: read())
      case .appendRectangle:
        context.addRect(read())
      case .appendRoundedRect:
        let path = CGPath(
          roundedRect: read(),
          cornerWidth: read(),
          cornerHeight: read(),
          transform: nil
        )
        context.addPath(path)
      case .beginTransparencyLayer:
        context.beginTransparencyLayer(auxiliaryInfo: nil)
      case .blendMode:
        context.setBlendMode(read())
      case .clip:
        context.clip(using: read())
      case .clipToRect:
        context.clip(to: read(CGRect.self))
      case .closePath:
        context.closePath()
      case .colorRenderingIntent:
        context.setRenderingIntent(read())
      case .concatCTM:
        context.concatenate(read())
      case .curveTo:
        context.addCurve(to: read(), control1: read(), control2: read())
      case .dash:
        let dashPattern: BCDashPattern = read()
        context.setLineDash(
          phase: dashPattern.phase,
          lengths: dashPattern.lengths
        )
      case .drawPath:
        context.drawPath(using: read())
      case .endTransparencyLayer:
        context.endTransparencyLayer()
      case .fill:
        context.fillPath(using: read())
      case .fillColor:
        let color: BCRGBAColor = read()
        context.setFillColor(color.components)
      case .fillEllipse:
        context.fillEllipse(in: read())
      case .flatness:
        context.setFlatness(read())
      case .globalAlpha:
        context.setAlpha(read())
      case .lineCapStyle:
        context.setLineCap(read())
      case .lineJoinStyle:
        context.setLineJoin(read())
      case .lineTo:
        context.addLine(to: read())
      case .lineWidth:
        context.setLineWidth(read())
      case .linearGradient:
        let gradient = commons.gradients[read()]!
        drawLinearGradient(gradient)
      case .linearGradientInlined:
        let gradient = readGradient()
        drawLinearGradient(gradient)
      case .lines:
        context.addLines(between: read())
      case .moveTo:
        context.move(to: read())
      case .radialGradient:
        let gradient = commons.gradients[read()]!
        drawRadialGradient(gradient)
      case .radialGradientInlined:
        let gradient = readGradient()
        drawRadialGradient(gradient)
      case .replacePathWithStrokePath:
        context.replacePathWithStrokedPath()
      case .restoreGState:
        context.restoreGState()
      case .saveGState:
        context.saveGState()
      case .stroke:
        context.strokePath()
      case .strokeColor:
        let color: BCRGBAColor = read()
        context.setStrokeColor(color.components)
      case .subrouteWithId:
        let subroute = commons.subroutes[read()]!
        BytecodeRunner(subroute, commons).run()
      case .shadow:
        drawShadow()
      }
    }
  }
}

public func runBytecode(_ context: CGContext, fromData data: Data) {
  let sz = data.count
  data.withUnsafeBytes {
    let ptr = $0.bindMemory(to: UInt8.self).baseAddress!
    runBytecode(context, ptr, sz)
  }
}

@_cdecl("runBytecode") func runBytecode(
  _ context: CGContext,
  _ start: UnsafePointer<UInt8>,
  _ len: Int
) {
  let cs = CGColorSpaceCreateDeviceRGB()
  context.setFillColorSpace(cs)
  context.setStrokeColorSpace(cs)
  let state = BytecodeRunner.State(position: start, remaining: BCSizeType(len))
  let commons = BytecodeRunner.Commons(context, cs)
  BytecodeRunner(state, commons).run()
}
