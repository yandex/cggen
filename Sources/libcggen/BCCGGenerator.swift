import Base
import BCCommon
import CoreGraphics
import Foundation

typealias Bytecode = [UInt8]

private protocol BytecodeEncodable {
  func encode(to bytecode: inout Bytecode)
}

private func >>(_: (), _: inout Bytecode) {}

private func >> <T: BytecodeEncodable>(value: T, bytecode: inout Bytecode) {
  value.encode(to: &bytecode)
}

private func >> <
  T0: BytecodeEncodable, T1: BytecodeEncodable
>(value: (T0, T1), bytecode: inout Bytecode) {
  value.0 >> bytecode
  value.1 >> bytecode
}

private func >> <
  T0: BytecodeEncodable, T1: BytecodeEncodable, T2: BytecodeEncodable
>(value: (T0, T1, T2), bytecode: inout Bytecode) {
  value.0 >> bytecode
  value.1 >> bytecode
  value.2 >> bytecode
}

private func >> <
  T0: BytecodeEncodable, T1: BytecodeEncodable,
  T2: BytecodeEncodable, T3: BytecodeEncodable
>(value: (T0, T1, T2, T3), bytecode: inout Bytecode) {
  value.0 >> bytecode
  value.1 >> bytecode
  value.2 >> bytecode
  value.3 >> bytecode
}

private func >> <
  T0: BytecodeEncodable, T1: BytecodeEncodable, T2: BytecodeEncodable,
  T3: BytecodeEncodable, T4: BytecodeEncodable
>(value: (T0, T1, T2, T3, T4), bytecode: inout Bytecode) {
  value.0 >> bytecode
  value.1 >> bytecode
  value.2 >> bytecode
  value.3 >> bytecode
  value.4 >> bytecode
}

extension UInt8: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    bytecode.append(self)
  }
}

extension UInt32: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    withUnsafeBytes(of: littleEndian) { bytecode.append(contentsOf: $0) }
  }
}

extension CGFloat: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    Float32(self).bitPattern >> bytecode
  }
}

extension Bool: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    bytecode.append(self ? 1 : 0)
  }
}

extension CGPoint: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    (x, y) >> bytecode
  }
}

extension CGSize: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    (width, height) >> bytecode
  }
}

extension Array: BytecodeEncodable where Element: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    UInt32(count) >> bytecode
    forEach { $0 >> bytecode }
  }
}

extension CGRect: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    origin >> bytecode
    size >> bytecode
  }
}

extension RawRepresentable where RawValue: FixedWidthInteger {
  func encode(to bytecode: inout Bytecode) {
    bytecode.append(UInt8(rawValue))
  }
}

extension Command: BytecodeEncodable {}

extension BCFillRule: BytecodeEncodable {
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

extension BCDashPattern: BytecodeEncodable {
  init(_ other: DashPattern) {
    self.init(phase: other.phase, lengths: other.lengths)
  }

  func encode(to bytecode: inout Bytecode) {
    (phase, lengths) >> bytecode
  }
}

extension CGPathDrawingMode: BytecodeEncodable {}

extension CGAffineTransform: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    [a, b, c, d, tx, ty].forEach { $0 >> bytecode }
  }
}

extension CGLineJoin: BytecodeEncodable {}

extension CGLineCap: BytecodeEncodable {}

extension CGColorRenderingIntent: BytecodeEncodable {}

private func zipComponent(val: CGFloat) -> UInt8 {
  UInt8(val * CGFloat(UInt8.max))
}

extension BCRGBColor: BytecodeEncodable {
  init(_ other: RGBCGColor) {
    let denormed = other.denorm(UInt8.self)
    self.init(r: denormed.red, g: denormed.green, b: denormed.blue)
  }

  func encode(to bytecode: inout Bytecode) {
    (red, green, blue) >> bytecode
  }
}

extension BCRGBAColor: BytecodeEncodable {
  init(_ other: RGBACGColor) {
    let denormed = other.denormColor(UInt8.self)
    self.init(
      r: denormed.red, g: denormed.green, b: denormed.blue,
      alpha: denormed.alpha
    )
  }

  func encode(to bytecode: inout Bytecode) {
    (red, green, blue, alpha) >> bytecode
  }
}

private func >>(value: [(CGFloat, RGBACGColor)], bytecode: inout Bytecode) {
  UInt32(value.count) >> bytecode
  value.forEach { ($0.0, BCRGBAColor($0.1)) >> bytecode }
}

extension Gradient: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    locationAndColors >> bytecode
  }
}

extension BCShadow: BytecodeEncodable {
  init(_ other: Shadow) {
    self.init(
      offset: other.offset, blur: other.blur, color: BCRGBAColor(other.color)
    )
  }

  func encode(to bytecode: inout Bytecode) {
    (offset, blur, color) >> bytecode
  }
}

extension CGBlendMode: BytecodeEncodable {}

extension CGGradientDrawingOptions: BytecodeEncodable {}

extension BCCoordinateUnits: BytecodeEncodable {
  init(_ units: DrawStep.Units) {
    switch units {
    case .objectBoundingBox:
      self = .objectBoundingBox
    case .userSpaceOnUse:
      self = .userSpaceOnUse
    }
  }
}

extension BCLinearGradientDrawingOptions: BytecodeEncodable {
  init(_ opts: DrawStep.LinearGradientDrawingOptions) {
    self.init(
      start: opts.startPoint,
      end: opts.endPoint,
      options: opts.options,
      units: BCCoordinateUnits(opts.units)
    )
  }

  func encode(to bytecode: inout Bytecode) {
    (start, end, options, units) >> bytecode
  }
}

extension BCCubicCurve: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    (control1, control2, to) >> bytecode
  }
}

extension BCRadialGradientDrawingOptions: BytecodeEncodable {
  init(_ opts: DrawStep.RadialGradientDrawingOptions) {
    self.init(
      startCenter: opts.startCenter,
      startRadius: opts.startRadius,
      endCenter: opts.endCenter,
      endRadius: opts.endRadius,
      drawingOptions: opts.options
    )
  }

  func encode(to bytecode: inout Bytecode) {
    (startCenter, startRadius, endCenter, endRadius, drawingOptions) >> bytecode
  }
}

private func generateSteps(
  steps: [DrawStep],
  context: Context,
  bytecode: inout Bytecode
) {
  func encode<T>(
    _ command: Command,
    _: T.Type, _ value: T, _ encoder: (T, inout Bytecode) -> Void
  ) {
    command >> bytecode
    encoder(value, &bytecode)
  }
  func gradient(
    _ name: String, _ options: DrawStep.LinearGradientDrawingOptions
  ) -> (UInt32, BCLinearGradientDrawingOptions) {
    (context.gradientsIds[name]!, BCLinearGradientDrawingOptions(options))
  }
  func gradient(
    _ name: String, _ options: DrawStep.RadialGradientDrawingOptions
  ) -> (UInt32, BCRadialGradientDrawingOptions) {
    (context.gradientsIds[name]!, BCRadialGradientDrawingOptions(options))
  }
  steps.forEach { (step: DrawStep) in
    switch step {
    case .saveGState:
      encode(.saveGState, Command.SaveGStateArgs.self, (), >>)
    case .restoreGState:
      encode(.restoreGState, Command.RestoreGStateArgs.self, (), >>)
    case let .moveTo(to):
      encode(.moveTo, Command.MoveToArgs.self, to, >>)
    case let .curveTo(c1, c2, end):
      encode(
        .curveTo,
        Command.CurveToArgs.self,
        BCCubicCurve(control1: c1, control2: c2, to: end), >>
      )
    case let .lineTo(to):
      encode(.lineTo, Command.LineToArgs.self, to, >>)
    case let .appendRectangle(rect):
      encode(.appendRectangle, Command.AppendRectangleArgs.self, rect, >>)
    case let .appendRoundedRect(rect, rx, ry):
      encode(
        .appendRoundedRect,
        Command.AppendRoundedRectArgs.self,
        (rect, rx: rx, ry: ry), >>
      )
    case let .addArc(center, radius, startAngle, endAngle, clockwise):
      encode(
        .addArc,
        Command.AddArcArgs.self,
        (center, radius, startAngle, endAngle, clockwise), >>
      )
    case .closePath:
      encode(.closePath, Command.ClosePathArgs.self, (), >>)
    case .replacePathWithStrokePath:
      encode(
        .replacePathWithStrokePath,
        Command.ReplacePathWithStrokePathArgs.self, (), >>
      )
    case let .lines(lines):
      encode(.lines, Command.LinesArgs.self, lines, >>)
    case .clip:
      encode(.clip, Command.ClipArgs.self, (), >>)
    case let .clipWithRule(rule):
      encode(.clipWithRule, Command.ClipWithRuleArgs.self, BCFillRule(rule), >>)
    case let .clipToRect(rect):
      encode(.clipToRect, Command.ClipToRectArgs.self, rect, >>)
    case let .dash(pattern):
      encode(.dash, Command.DashArgs.self, BCDashPattern(pattern), >>)
    case let .dashPhase(phase):
      encode(.dashPhase, Command.DashPhaseArgs.self, phase, >>)
    case let .dashLenghts(lenghts):
      encode(.dashLenghts, Command.DashLenghtsArgs.self, lenghts, >>)
    case .fill:
      encode(.fill, Command.FillArgs.self, (), >>)
    case let .fillWithRule(rule):
      encode(.fillWithRule, Command.FillWithRuleArgs.self, BCFillRule(rule), >>)
    case let .fillEllipse(rect):
      encode(.fillEllipse, Command.FillEllipseArgs.self, rect, >>)
    case .stroke:
      encode(.stroke, Command.StrokeArgs.self, (), >>)
    case let .drawPath(mode):
      encode(.drawPath, Command.DrawPathArgs.self, mode, >>)
    case let .addEllipse(rect):
      encode(.addEllipse, Command.AddEllipseArgs.self, rect, >>)
    case let .concatCTM(transform):
      encode(.concatCTM, Command.ConcatCTMArgs.self, transform, >>)
    case let .flatness(f):
      encode(.flatness, Command.FlatnessArgs.self, f, >>)
    case let .lineWidth(width):
      encode(.lineWidth, Command.LineWidthArgs.self, width, >>)
    case let .lineJoinStyle(lineJoin):
      encode(.lineJoinStyle, Command.LineJoinStyleArgs.self, lineJoin, >>)
    case let .lineCapStyle(cap):
      encode(.lineCapStyle, Command.LineCapStyleArgs.self, cap, >>)
    case let .colorRenderingIntent(intent):
      encode(
        .colorRenderingIntent,
        Command.ColorRenderingIntentArgs.self, intent, >>
      )
    case let .globalAlpha(alpha):
      encode(.globalAlpha, Command.GlobalAlphaArgs.self, alpha, >>)
    case let .strokeColor(color):
      encode(.strokeColor, Command.StrokeColorArgs.self, BCRGBColor(color), >>)
    case let .strokeAlpha(alpha):
      encode(.strokeAlpha, Command.StrokeAlphaArgs.self, alpha, >>)
    case let .fillColor(color):
      encode(.fillColor, Command.FillColorArgs.self, BCRGBColor(color), >>)
    case let .fillAlpha(alpha):
      encode(.fillAlpha, Command.FillAlphaArgs.self, alpha, >>)
    case .strokeNone:
      encode(.strokeNone, Command.StrokeNoneArgs.self, (), >>)
    case .fillNone:
      encode(.fillNone, Command.FillNoneArgs.self, (), >>)
    case let .fillRule(rule):
      encode(.fillRule, Command.FillRuleArgs.self, BCFillRule(rule), >>)
    case .fillAndStroke:
      encode(.fillAndStroke, Command.FillAndStrokeArgs.self, (), >>)
    case .setGlobalAlphaToFillAlpha:
      encode(
        .setGlobalAlphaToFillAlpha,
        Command.SetGlobalAlphaToFillAlphaArgs.self, (), >>
      )
    case let .linearGradient(name, options):
      encode(
        .linearGradient,
        Command.LinearGradientArgs.self, gradient(name, options), >>
      )
    case let .radialGradient(name, options):
      encode(
        .radialGradient,
        Command.RadialGradientArgs.self, gradient(name, options), >>
      )
    case let .fillLinearGradient(name, options):
      encode(
        .fillLinearGradient,
        Command.FillLinearGradientArgs.self, gradient(name, options), >>
      )
    case let .fillRadialGradient(name, options):
      encode(
        .fillRadialGradient,
        Command.FillRadialGradientArgs.self, gradient(name, options), >>
      )
    case let .strokeLinearGradient(name, options):
      encode(
        .strokeLinearGradient,
        Command.StrokeLinearGradientArgs.self, gradient(name, options), >>
      )
    case let .strokeRadialGradient(name, options):
      encode(
        .strokeRadialGradient,
        Command.StrokeRadialGradientArgs.self, gradient(name, options), >>
      )
    case let .subrouteWithName(name):
      encode(
        .subrouteWithId,
        Command.SubrouteWithIdArgs.self, context.subroutesIds[name]!, >>
      )
    case let .shadow(shadow):
      encode(.shadow, Command.ShadowArgs.self, BCShadow(shadow), >>)
    case let .blendMode(mode):
      encode(.blendMode, Command.BlendModeArgs.self, mode, >>)
    case .beginTransparencyLayer:
      encode(
        .beginTransparencyLayer,
        Command.BeginTransparencyLayerArgs.self, (), >>
      )
    case .endTransparencyLayer:
      encode(
        .endTransparencyLayer,
        Command.EndTransparencyLayerArgs.self, (), >>
      )
    case let .composite(steps):
      generateSteps(steps: steps, context: context, bytecode: &bytecode)
    case .endPath:
      // FIXME: Implement end path
      break
    case .fillColorSpace, .strokeColorSpace:
      fatalError("Not implemented")
    }
  }
}

private func generateSubroutes(
  subroutes: [String: DrawRoutine],
  context: Context,
  bytecode: inout Bytecode
) {
  UInt32(subroutes.count) >> bytecode
  for subroute in subroutes {
    let counter = UInt32(context.subroutesIds.count)
    context.subroutesIds[subroute.key] = counter
    counter >> bytecode

    var subrouteBytecode = Bytecode()
    generateRoute(
      route: subroute.value,
      context: context,
      bytecode: &subrouteBytecode
    )
    UInt32(subrouteBytecode.count) >> bytecode
    bytecode.append(contentsOf: subrouteBytecode)
  }
}

private func generateGradients(
  gradients: [String: Gradient],
  context: Context,
  bytecode: inout Bytecode
) {
  UInt32(gradients.count) >> bytecode
  var counter: UInt32 = 0
  for gradient in gradients {
    counter += 1
    context.gradientsIds[gradient.key] = counter
    counter >> bytecode
    gradient.value >> bytecode
  }
}

private func generateRoute(
  route: DrawRoutine,
  context: Context,
  bytecode: inout Bytecode
) {
  generateGradients(
    gradients: route.gradients,
    context: context,
    bytecode: &bytecode
  )
  generateSubroutes(
    subroutes: route.subroutines,
    context: context,
    bytecode: &bytecode
  )
  generateSteps(steps: route.steps, context: context, bytecode: &bytecode)
}

private class Context {
  var gradientsIds: [String: UInt32] = [:]
  var subroutesIds: [String: UInt32] = [:]
}

func generateRouteBytecode(route: DrawRoutine) -> [UInt8] {
  var bytecode = Bytecode()
  generateRoute(route: route, context: Context(), bytecode: &bytecode)
  return bytecode
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
    \(params.style.drawingHandlerPrefix)void \(params.prefix)Draw\(
      image.name.upperCamelCase
    )ImageInContext(CGContextRef context) {
      runBytecode(context, \(bytecodeName), \(bytecode.count));
    }
    """ + params.descriptorLines(for: image).joined(separator: "\n")
  }

  func fileEnding() -> String {
    ""
  }
}
