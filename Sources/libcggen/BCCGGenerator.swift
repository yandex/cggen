import Base
import BCCommon
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

extension CGPathFillRule: ByteCodable {
  var byteCode: [UInt8] {
    [UInt8(rawValue)]
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

extension RGBACGColor: ByteCodable {
  var byteCode: [UInt8] {
    [red, green, blue].map(zipComponent) + alpha.byteCode
  }
}

extension ByteCodable where Self == [(CGFloat, RGBACGColor)] {
  var byteCode: [UInt8] {
    UInt32(self.count).byteCode + self.flatMap { $0.0.byteCode + $0.1.byteCode }
  }
}

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
    case let .clip(rule):
      return byteCommand(.clip, rule)
    case let .clipToRect(rect):
      return byteCommand(.clipToRect, rect)
    case let .dash(pattern):
      return byteCommand(.dash, pattern)
    case let .fill(rule):
      return byteCommand(.fill, rule)
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
      return byteCommand(.strokeColor, color)
    case let .fillColor(color):
      return byteCommand(.fillColor, color)
    case let .linearGradient(name, options):
      return byteCommand(
        .linearGradient,
        context.gradientsIds[name]!,
        options.startPoint,
        options.endPoint,
        options.options
      )
    case let .radialGradient(name, options):
      return byteCommand(
        .radialGradient,
        context.gradientsIds[name]!,
        options.startCenter,
        options.startRadius,
        options.endCenter,
        options.endRadius,
        options.options
      )
    case let .linearGradientInlined(gradient, options):
      return byteCommand(
        .linearGradientInlined,
        gradient,
        options.startPoint,
        options.endPoint,
        options.options
      )
    case let .radialGradientInlined(gradient, options):
      return byteCommand(
        .radialGradientInlined,
        gradient,
        options.startCenter,
        options.startRadius,
        options.endCenter,
        options.endRadius,
        options.options
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
  subroutes: [String: DrawRoute],
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

private func generateRoute(route: DrawRoute, context: Context) -> [UInt8] {
  generateGradients(gradients: route.gradients, context: context)
    + generateSubroutes(subroutes: route.subroutes, context: context)
    + generateSteps(steps: route.steps, context: context)
}

private class Context {
  var gradientsIds: [String: UInt32] = [:]
  var subroutesIds: [String: UInt32] = [:]
}

func generateRouteBytecode(route: DrawRoute) -> [UInt8] {
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
    let bytecodeName = "\(image.name)Bytecode"
    let bytecode = generateRouteBytecode(route: image.route)
    return """
    static const uint8_t \(bytecodeName)[] = { /* size: \(bytecode.count)*/
      \(bytecode.map { "\($0), " }.joined())
    };
    void \(params.prefix)Draw\(image.name.upperCamelCase)ImageInContext(CGContextRef context) {
      runBytecode(context, \(bytecodeName), sizeof(\(bytecodeName)));
    }
    """
  }

  func fileEnding() -> String {
    ""
  }
}
