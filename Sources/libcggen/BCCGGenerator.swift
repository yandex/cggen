import Base
import BCCommon
import CoreGraphics
import Foundation

private protocol ByteCodable {
  var byteCode: [UInt8] { get }
}

extension UInt32: ByteCodable {
  var byteCode: [UInt8] {
    withUnsafeBytes(of: littleEndian, Array.init)
  }
}

extension CGFloat: ByteCodable {
  var byteCode: [UInt8] {
    Float32(self).bitPattern.byteCode
  }
}

extension Bool: ByteCodable {
  var byteCode: [UInt8] {
    [self ? 1 : 0]
  }
}

extension CGPoint: ByteCodable {
  var byteCode: [UInt8] {
    x.byteCode + y.byteCode
  }
}

extension Array: ByteCodable where Element: ByteCodable {
  var byteCode: [UInt8] {
    UInt32(count).byteCode + flatMap(\.byteCode)
  }
}

extension CGRect: ByteCodable {
  var byteCode: [UInt8] {
    origin.byteCode + size.byteCode
  }
}

extension BCFillRule: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
  }

  init(_ cg: CGPathFillRule) {
    switch cg {
    case .winding:
      self = .winding
    case .evenOdd:
      self = .evenOdd
    @unknown default:
      fatalError()
    }
  }
}

extension DashPattern: ByteCodable {
  var byteCode: [UInt8] {
    phase.byteCode + lengths.byteCode
  }
}

extension CGPathDrawingMode: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
  }
}

extension CGAffineTransform: ByteCodable {
  var byteCode: [UInt8] {
    [a, b, c, d, tx, ty].flatMap(\.byteCode)
  }
}

extension CGLineJoin: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
  }
}

extension CGLineCap: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
  }
}

extension CGColorRenderingIntent: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
  }
}

private func zipComponent(val: CGFloat) -> UInt8 {
  UInt8(val * CGFloat(UInt8.max))
}

extension RGBACGColor {
  var byteCode: [UInt8] {
    [red, green, blue].map(zipComponent) + alpha.byteCode
  }
}

extension RGBCGColor {
  var byteCode: [UInt8] {
    [red, green, blue].map(zipComponent)
  }
}

// swiftformat:disable redundantSelf
extension ByteCodable where Self == [(CGFloat, RGBACGColor)] {
  var byteCode: [UInt8] {
    UInt32(self.count).byteCode + self.flatMap { $0.0.byteCode + $0.1.byteCode }
  }
}

// swiftformat:enable redundantSelf

extension Gradient: ByteCodable {
  var byteCode: [UInt8] {
    locationAndColors.byteCode
  }
}

extension CGSize: ByteCodable {
  var byteCode: [UInt8] {
    width.byteCode + height.byteCode
  }
}

extension Shadow: ByteCodable {
  var byteCode: [UInt8] {
    offset.byteCode + blur.byteCode + color.byteCode
  }
}

extension CGBlendMode: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
  }
}

extension CGGradientDrawingOptions: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
  }
}

extension BCCoordinateUnits: ByteCodable {
  init(_ units: DrawStep.Units) {
    switch units {
    case .objectBoundingBox:
      self = .objectBoundingBox
    case .userSpaceOnUse:
      self = .userSpaceOnUse
    }
  }

  var byteCode: [UInt8] { [rawValue] }
}

extension BCLinearGradientDrawingOptions: ByteCodable {
  init(_ opts: DrawStep.LinearGradientDrawingOptions) {
    self.init(
      start: opts.startPoint,
      end: opts.endPoint,
      options: opts.options,
      units: BCCoordinateUnits(opts.units)
    )
  }
  
  var byteCode: [UInt8] {
    start.byteCode +
    end.byteCode +
    options.byteCode +
    units.byteCode
  }
}

extension BCRadialGradientDrawingOptions: ByteCodable {
  init(_ opts: DrawStep.RadialGradientDrawingOptions) {
    self.init(
      startCenter: opts.startCenter,
      startRadius: opts.startRadius,
      endCenter: opts.endCenter,
      endRadius: opts.endRadius,
      drawingOptions: opts.options
    )
  }
  
  var byteCode: [UInt8] {
    startCenter.byteCode +
    startRadius.byteCode +
    endCenter.byteCode +
    endRadius.byteCode +
    drawingOptions.byteCode
  }
}

private func byteCommand(_ code: Command, _ args: ByteCodable...) -> [UInt8] {
  [code.rawValue] + args.flatMap(\.byteCode)
}

private func generateSteps(steps: [DrawStep], context: Context) -> [UInt8] {
  steps.flatMap { (step: DrawStep) -> [UInt8] in
    switch step {
    case .saveGState:
      return byteCommand(.saveGState)
    case .restoreGState:
      return byteCommand(.restoreGState)
    case let .moveTo(to):
      return byteCommand(.moveTo, to)
    case let .curveTo(c1, c2, end):
      return byteCommand(.curveTo, c1, c2, end)
    case let .lineTo(to):
      return byteCommand(.lineTo, to)
    case let .appendRectangle(rect):
      return byteCommand(.appendRectangle, rect)
    case let .appendRoundedRect(rect, rx, ry):
      return byteCommand(.appendRoundedRect, rect, rx, ry)
    case let .addArc(center, radius, startAngle, endAngle, clockwise):
      return byteCommand(
        .addArc,
        center,
        radius,
        startAngle,
        endAngle,
        clockwise
      )
    case .closePath:
      return byteCommand(.closePath)
    case .replacePathWithStrokePath:
      return byteCommand(.replacePathWithStrokePath)
    case let .lines(lines):
      return byteCommand(.lines, lines)
    case .clip:
      return byteCommand(.clip)
    case let .clipWithRule(rule):
      return byteCommand(.clipWithRule, BCFillRule(rule))
    case let .clipToRect(rect):
      return byteCommand(.clipToRect, rect)
    case let .dash(pattern):
      return byteCommand(.dash, pattern)
    case let .dashPhase(phase):
      return byteCommand(.dashPhase, phase)
    case let .dashLenghts(lenghts):
      return byteCommand(.dashLenghts, lenghts)
    case .fill:
      return byteCommand(.fill)
    case let .fillWithRule(rule):
      return byteCommand(.fillWithRule, BCFillRule(rule))
    case let .fillEllipse(rect):
      return byteCommand(.fillEllipse, rect)
    case .stroke:
      return byteCommand(.stroke)
    case let .drawPath(mode):
      return byteCommand(.drawPath, mode)
    case let .addEllipse(rect):
      return byteCommand(.addEllipse, rect)
    case let .concatCTM(transform):
      return byteCommand(.concatCTM, transform)
    case let .flatness(f):
      return byteCommand(.flatness, f)
    case let .lineWidth(width):
      return byteCommand(.lineWidth, width)
    case let .lineJoinStyle(lineJoin):
      return byteCommand(.lineJoinStyle, lineJoin)
    case let .lineCapStyle(cap):
      return byteCommand(.lineCapStyle, cap)
    case let .colorRenderingIntent(intent):
      return byteCommand(.colorRenderingIntent, intent)
    case let .globalAlpha(alpha):
      return byteCommand(.globalAlpha, alpha)
    case let .strokeColor(color):
      return byteCommand(.strokeColor) + color.byteCode
    case let .strokeAlpha(alpha):
      return byteCommand(.strokeAlpha, alpha)
    case let .fillColor(color):
      return byteCommand(.fillColor) + color.byteCode
    case let .fillAlpha(alpha):
      return byteCommand(.fillAlpha, alpha)
    case .strokeNone:
      return byteCommand(.strokeNone)
    case .fillNone:
      return byteCommand(.fillNone)
    case let .fillRule(rule):
      return byteCommand(.fillRule, BCFillRule(rule))
    case .fillAndStroke:
      return byteCommand(.fillAndStroke)
    case .setGlobalAlphaToFillAlpha:
      return byteCommand(.setGlobalAlphaToFillAlpha)
    case let .linearGradient(name, options):
      return byteCommand(
        .linearGradient,
        context.gradientsIds[name]!,
        BCLinearGradientDrawingOptions(options)
      )
    case let .radialGradient(name, options):
      return byteCommand(
        .radialGradient,
        context.gradientsIds[name]!,
        BCRadialGradientDrawingOptions(options)
      )
    case let .fillLinearGradient(name, options):
      return byteCommand(
        .fillLinearGradient,
        context.gradientsIds[name]!,
        BCLinearGradientDrawingOptions(options)
      )
    case let .fillRadialGradient(name, options):
      return byteCommand(
        .fillRadialGradient,
        context.gradientsIds[name]!,
        BCRadialGradientDrawingOptions(options)
      )
    case let .strokeLinearGradient(name, options):
      return byteCommand(
        .strokeLinearGradient,
        context.gradientsIds[name]!,
        BCLinearGradientDrawingOptions(options)
      )
    case let .strokeRadialGradient(name, options):
      return byteCommand(
        .strokeRadialGradient,
        context.gradientsIds[name]!,
        BCRadialGradientDrawingOptions(options)
      )
    case let .subrouteWithName(name):
      return byteCommand(.subrouteWithId, context.subroutesIds[name]!)
    case let .shadow(shadow):
      return byteCommand(.shadow, shadow)
    case let .blendMode(mode):
      return byteCommand(.blendMode, mode)
    case .beginTransparencyLayer:
      return byteCommand(.beginTransparencyLayer)
    case .endTransparencyLayer:
      return byteCommand(.endTransparencyLayer)
    case let .composite(steps):
      return generateSteps(steps: steps, context: context)
    case .endPath:
      // .endPath is rather important, this should be fixed in future
      return []
    case .fillColorSpace, .strokeColorSpace:
      fatalError("Not implemented")
    }
  }
}

private func generateSubroutes(
  subroutes: [String: DrawRoutine],
  context: Context
) -> [UInt8] {
  var res = UInt32(subroutes.count).byteCode
  for subroute in subroutes {
    let counter = UInt32(context.subroutesIds.count)
    context.subroutesIds[subroute.key] = counter
    let subrouteBytecode = generateRoute(
      route: subroute.value,
      context: context
    )
    res += counter.byteCode + UInt32(subrouteBytecode.count)
      .byteCode + subrouteBytecode
  }
  return res
}

private func generateGradients(
  gradients: [String: Gradient],
  context: Context
) -> [UInt8] {
  var res = UInt32(gradients.count).byteCode
  for gradient in gradients {
    let counter = UInt32(context.gradientsIds.count)
    context.gradientsIds[gradient.key] = counter
    res += counter.byteCode + gradient.value.byteCode
  }
  return res
}

private func generateRoute(route: DrawRoutine, context: Context) -> [UInt8] {
  generateGradients(gradients: route.gradients, context: context)
    + generateSubroutes(subroutes: route.subroutines, context: context)
    + generateSteps(steps: route.steps, context: context)
}

private class Context {
  var gradientsIds: [String: UInt32] = [:]
  var subroutesIds: [String: UInt32] = [:]
}

func generateRouteBytecode(route: DrawRoutine) -> [UInt8] {
  generateRoute(route: route, context: Context())
}

struct BCCGGenerator: CoreGraphicsGenerator {
  var params: GenerationParams
  var headerImportPath: String?

  func filePreamble() -> String {
    let importLine = headerImportPath.map { "#import \"\($0)\"\n" } ?? ""
    return """
    \(importLine)
    void runBytecode(CGContextRef context, const uint8_t* arr, int len);

    """
  }

  func generateImageFunction(image: Image) -> String {
    let bytecodeName = "\(image.name.lowerCamelCase)Bytecode"
    let bytecode = generateRouteBytecode(route: image.route)
    return """
    static const uint8_t \(bytecodeName)[] = {
      \(bytecode.map(\.description).joined(separator: ", "))
    };
    \(params.style.drawingHandlerPrefix)void \(params.prefix)Draw\(image.name
      .upperCamelCase)ImageInContext(CGContextRef context) {
      runBytecode(context, \(bytecodeName), \(bytecode.count));
    }
    """ + params.descriptorLines(for: image).joined(separator: "\n")
  }

  func fileEnding() -> String {
    ""
  }
}
