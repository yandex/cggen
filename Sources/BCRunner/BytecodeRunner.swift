import CoreGraphics
import Foundation

import BCCommon

extension BCRGBAColor {
  var arrayForm:[CGFloat] {[red, green, blue, alpha]}
}

class BytecodeRunner {
  struct State {
    var position: UnsafePointer<UInt8>
    var remaining: Int
  }

  class Commons {
    var subroutes: [UInt32: State] = [:]
    var gradients: [UInt32: CGGradient] = [:]
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

  func advance(_ count: Int) {
    currentState.position += count
    currentState.remaining -= count
  }

  func readBytes<T: FixedWidthInteger>(_: T.Type = T.self) -> T {
    let size = MemoryLayout<T>.size
    precondition(size <= currentState.remaining)
    var ret: T = 0
    memcpy(&ret, currentState.position, size)
    advance(size)
    return T(littleEndian: ret)
  }

  func read<T: BytecodeElement> (_: T.Type = T.self) -> T {
    return T.readFrom(self)
  }
  
  func drawLinearGradient(_ gradient: CGGradient) {
    let context = commons.context
    let options:BCLinearGradientDrawingOptions = read()
    context.drawLinearGradient(gradient, start: options.start, end: options.end, options: options.options)
  }
  
  func drawRadialGradient(_ gradient: CGGradient) {
    let context = commons.context
    let options:BCRadialGradientDrawingOptions = read()
    context.drawRadialGradient(gradient, startCenter: options.startCenter, startRadius: options.startRadius, endCenter: options.endCenter, endRadius: options.endRadius, options: options.drawingOptions)
  }
  
  func readGradient() -> CGGradient {
    let gradienntDesc:BCGradient = read()
    let sz = gradienntDesc.count
    let cs = commons.cs
    var colors:[CGFloat] = []
    var locs:[CGFloat] = []
    colors.reserveCapacity(sz * 4)
    locs.reserveCapacity(sz)
    for t in gradienntDesc {
      colors.append(contentsOf: t.color.arrayForm)
      locs.append(t.location)
    }
    return CGGradient(colorSpace: cs, colorComponents: colors, locations: locs, count: sz)!
  }
  
  func drawShadow() {
    let context = commons.context
    let shadow:BCShadow = read()
    let ctm = context.ctm
    let cs = commons.cs
    let a = ctm.a
    let c = ctm.c
    let scaleX = sqrt(a * a + c * c)
    let offset = shadow.offset.applying(ctm)
    let blur = floor(shadow.blur * scaleX + 0.5)
    let color = CGColor(colorSpace: cs, components: shadow.color.arrayForm)
    context.setShadow(offset: offset, blur: blur, color: color)
  }
  
  func run() {
    let context = commons.context
    var gradients = commons.gradients
    var subroutes = commons.subroutes
    
    //MARK: Reading gradients and subroutes
    
    let gradientCount: UInt32 = read()
    for _ in 1...gradientCount {
      let id:UInt32 = read()
      gradients[id] = readGradient()
    }
    
    let subrouteCount: UInt32 = read()
    for _ in 1...subrouteCount {
      let id:UInt32 = read()
      let sz = Int(read(UInt32.self))
      let subroute = State(position: currentState.position, remaining: sz)
      subroutes[id] = subroute
      advance(sz)
    }
    
    //MARK: Executing commands
    
    while currentState.remaining > 0 {
      let command = Command(rawValue: read())!
      switch command {
      case .addArc:
        context.addArc(center: read(), radius: read(), startAngle: read(), endAngle: read(), clockwise: read())
      case .addEllipse:
        context.addEllipse(in: read())
      case .appendRectangle:
        context.addRect(read())
      case .appendRoundedRect:
        let path = CGPath(roundedRect: read(), cornerWidth: read(), cornerHeight: read(), transform: nil)
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
        let dashPattern:BCDashPattern = read()
        context.setLineDash(phase: dashPattern.phase, lengths: dashPattern.lengths)
      case .drawPath:
        context.drawPath(using: read())
      case .endTransparencyLayer:
        context.endTransparencyLayer()
      case .fill:
        context.fillPath(using: read())
      case .fillColor:
        let color:BCRGBAColor = read()
        context.setFillColor(color.arrayForm)
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
        let gradient = gradients[read()]!
        drawLinearGradient(gradient)
      case .linearGradientInlined:
        let gradient = readGradient()
        drawLinearGradient(gradient)
      case .lines:
        context.addLines(between: read())
      case .moveTo:
        context.move(to: read())
      case .radialGradient:
        let gradient = gradients[read()]!
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
        let color:BCRGBAColor = read()
        context.setStrokeColor(color.arrayForm)
      case .subrouteWithId:
        let id:UInt32 = read()
        let subroute = subroutes[id]!
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
  let state = BytecodeRunner.State(position: start, remaining: len)
  let commons = BytecodeRunner.Commons(context, cs)
  BytecodeRunner(state, commons).run()
}
