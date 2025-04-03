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

extension Optional: BytecodeEncodable where Wrapped: BytecodeEncodable {
  func encode(to bytecode: inout Bytecode) {
    switch self {
    case .some(let value):
      true >> bytecode
      value >> bytecode
    case .none:
      false >> bytecode
    }
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

extension DrawCommand: BytecodeEncodable {}
extension PathCommand: BytecodeEncodable {}

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
      units: BCCoordinateUnits(opts.units),
      transform: opts.transform
    )
  }

  func encode(to bytecode: inout Bytecode) {
    (start, end, options, units) >> bytecode
    transform >> bytecode
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
      drawingOptions: opts.options,
      transform: opts.transform
    )
  }

  func encode(to bytecode: inout Bytecode) {
    (startCenter, startRadius, endCenter, endRadius, drawingOptions) >> bytecode
    transform >> bytecode
  }
}

private func generateDrawSteps(
  steps: [DrawStep],
  context: Context,
  bytecode: inout Bytecode
) {
  func encode<T>(
    _ command: DrawCommand,
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
  for step in steps {
    switch step {
    case .saveGState:
      encode(.saveGState, DrawCommand.SaveGStateArgs.self, (), >>)
    case .restoreGState:
      encode(.restoreGState, DrawCommand.RestoreGStateArgs.self, (), >>)
    case let .pathSegment(segment):
      PathSegmentEncoding.encode(as: .drawCommand, segment, bytecode: &bytecode)
    case .replacePathWithStrokePath:
      encode(
        .replacePathWithStrokePath,
        DrawCommand.ReplacePathWithStrokePathArgs.self, (), >>
      )
    case .clip:
      encode(.clip, DrawCommand.ClipArgs.self, (), >>)
    case let .clipWithRule(rule):
      encode(
        .clipWithRule,
        DrawCommand.ClipWithRuleArgs.self,
        BCFillRule(rule),
        >>
      )
    case let .clipToRect(rect):
      encode(.clipToRect, DrawCommand.ClipToRectArgs.self, rect, >>)
    case let .dash(pattern):
      encode(.dash, DrawCommand.DashArgs.self, BCDashPattern(pattern), >>)
    case let .dashPhase(phase):
      encode(.dashPhase, DrawCommand.DashPhaseArgs.self, phase, >>)
    case let .dashLenghts(lenghts):
      encode(.dashLenghts, DrawCommand.DashLenghtsArgs.self, lenghts, >>)
    case .fill:
      encode(.fill, DrawCommand.FillArgs.self, (), >>)
    case let .fillWithRule(rule):
      encode(
        .fillWithRule,
        DrawCommand.FillWithRuleArgs.self,
        BCFillRule(rule),
        >>
      )
    case let .fillEllipse(rect):
      encode(.fillEllipse, DrawCommand.FillEllipseArgs.self, rect, >>)
    case .stroke:
      encode(.stroke, DrawCommand.StrokeArgs.self, (), >>)
    case let .drawPath(mode):
      encode(.drawPath, DrawCommand.DrawPathArgs.self, mode, >>)
    case let .concatCTM(transform):
      encode(.concatCTM, DrawCommand.ConcatCTMArgs.self, transform, >>)
    case let .flatness(f):
      encode(.flatness, DrawCommand.FlatnessArgs.self, f, >>)
    case let .lineWidth(width):
      encode(.lineWidth, DrawCommand.LineWidthArgs.self, width, >>)
    case let .lineJoinStyle(lineJoin):
      encode(.lineJoinStyle, DrawCommand.LineJoinStyleArgs.self, lineJoin, >>)
    case let .lineCapStyle(cap):
      encode(.lineCapStyle, DrawCommand.LineCapStyleArgs.self, cap, >>)
    case let .colorRenderingIntent(intent):
      encode(
        .colorRenderingIntent,
        DrawCommand.ColorRenderingIntentArgs.self, intent, >>
      )
    case let .globalAlpha(alpha):
      encode(.globalAlpha, DrawCommand.GlobalAlphaArgs.self, alpha, >>)
    case let .strokeColor(color):
      encode(
        .strokeColor,
        DrawCommand.StrokeColorArgs.self,
        BCRGBColor(color),
        >>
      )
    case let .strokeAlpha(alpha):
      encode(.strokeAlpha, DrawCommand.StrokeAlphaArgs.self, alpha, >>)
    case let .fillColor(color):
      encode(.fillColor, DrawCommand.FillColorArgs.self, BCRGBColor(color), >>)
    case let .fillAlpha(alpha):
      encode(.fillAlpha, DrawCommand.FillAlphaArgs.self, alpha, >>)
    case .strokeNone:
      encode(.strokeNone, DrawCommand.StrokeNoneArgs.self, (), >>)
    case .fillNone:
      encode(.fillNone, DrawCommand.FillNoneArgs.self, (), >>)
    case let .fillRule(rule):
      encode(.fillRule, DrawCommand.FillRuleArgs.self, BCFillRule(rule), >>)
    case .fillAndStroke:
      encode(.fillAndStroke, DrawCommand.FillAndStrokeArgs.self, (), >>)
    case .setGlobalAlphaToFillAlpha:
      encode(
        .setGlobalAlphaToFillAlpha,
        DrawCommand.SetGlobalAlphaToFillAlphaArgs.self, (), >>
      )
    case let .linearGradient(name, options):
      encode(
        .linearGradient,
        DrawCommand.LinearGradientArgs.self, gradient(name, options), >>
      )
    case let .radialGradient(name, options):
      encode(
        .radialGradient,
        DrawCommand.RadialGradientArgs.self, gradient(name, options), >>
      )
    case let .fillLinearGradient(name, options):
      encode(
        .fillLinearGradient,
        DrawCommand.FillLinearGradientArgs.self, gradient(name, options), >>
      )
    case let .fillRadialGradient(name, options):
      encode(
        .fillRadialGradient,
        DrawCommand.FillRadialGradientArgs.self, gradient(name, options), >>
      )
    case let .strokeLinearGradient(name, options):
      encode(
        .strokeLinearGradient,
        DrawCommand.StrokeLinearGradientArgs.self, gradient(name, options), >>
      )
    case let .strokeRadialGradient(name, options):
      encode(
        .strokeRadialGradient,
        DrawCommand.StrokeRadialGradientArgs.self, gradient(name, options), >>
      )
    case let .subrouteWithName(name):
      encode(
        .subrouteWithId,
        DrawCommand.SubrouteWithIdArgs.self, context.subroutesIds[name]!, >>
      )
    case let .shadow(shadow):
      encode(.shadow, DrawCommand.ShadowArgs.self, BCShadow(shadow), >>)
    case let .blendMode(mode):
      encode(.blendMode, DrawCommand.BlendModeArgs.self, mode, >>)
    case .beginTransparencyLayer:
      encode(
        .beginTransparencyLayer,
        DrawCommand.BeginTransparencyLayerArgs.self, (), >>
      )
    case .endTransparencyLayer:
      encode(
        .endTransparencyLayer,
        DrawCommand.EndTransparencyLayerArgs.self, (), >>
      )
    case let DrawStep.composite(steps):
      generateDrawSteps(steps: steps, context: context, bytecode: &bytecode)
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
  generateDrawSteps(steps: route.steps, context: context, bytecode: &bytecode)
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

func generatePathBytecode(route: PathRoutine) -> [UInt8] {
  var bytecode = Bytecode()
  PathSegmentEncoding.generateSteps(
    as: .pathCommand,
    steps: route.content,
    bytecode: &bytecode
  )
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
    void runPathBytecode(CGMutablePathRef path, const uint8_t* arr, int len);
    """
  }

  func generateImageFunctions(images: [Image]) throws -> String {
    images.map { generateImageFunction(image: $0) }.joined(separator: "\n\n")
  }

  private func generateImageFunction(image: Image) -> String {
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

  func generatePathFuncton(path: PathRoutine) -> String {
    let bytecodeName = "\(path.id.lowerCamelCase)Bytecode"
    let bytecode = generatePathBytecode(route: path)
    let camel = path.id.upperCamelCase
    return """
    static const uint8_t \(bytecodeName)[] = {
      \(bytecode.map(\.description).joined(separator: ", "))
    };
    void \(params.prefix)\(camel)Path(CGMutablePathRef path) {
      runPathBytecode(path, \(bytecodeName), \(bytecode.count));
    }
    """
  }

  func fileEnding() -> String {
    ""
  }
}

enum PathSegmentEncoding {
  enum PathSegmentCommandKind {
    case drawCommand
    case pathCommand
  }

  static func encode(
    as kind: PathSegmentCommandKind,
    _ segment: PathSegment,
    bytecode: inout Bytecode
  ) {
    switch kind {
    case .drawCommand:
      encodeAsDrawCommand(segment, bytecode: &bytecode)
    case .pathCommand:
      encodeAsPathCommand(segment, bytecode: &bytecode)
    }
  }

  static func generateSteps(
    as kind: PathSegmentCommandKind,
    steps: [PathSegment],
    bytecode: inout Bytecode
  ) {
    switch kind {
    case .drawCommand:
      generateStepsAsDrawCommands(steps: steps, bytecode: &bytecode)
    case .pathCommand:
      generateStepsAsPathCommands(steps: steps, bytecode: &bytecode)
    }
  }

  private static func generateStepsAsPathCommands(
    steps segments: [PathSegment],
    bytecode: inout Bytecode
  ) {
    for segment in segments {
      encodeAsPathCommand(segment, bytecode: &bytecode)
    }
  }

  private static func generateStepsAsDrawCommands(
    steps segments: [PathSegment],
    bytecode: inout Bytecode
  ) {
    for segment in segments {
      encodeAsDrawCommand(segment, bytecode: &bytecode)
    }
  }

  private static func encodeAsPathCommand(
    _ segment: PathSegment,
    bytecode: inout Bytecode
  ) {
    func encode<T>(
      _ pathCommand: PathCommand,
      _: T.Type, _ value: T, _ encoder: (T, inout Bytecode) -> Void
    ) {
      pathCommand >> bytecode
      encoder(value, &bytecode)
    }

    switch segment {
    case let .moveTo(to):
      encode(.moveTo, PathCommand.MoveToArgs.self, to, >>)
    case let .curveTo(c1, c2, end):
      encode(
        .curveTo,
        PathCommand.CurveToArgs.self,
        BCCubicCurve(control1: c1, control2: c2, to: end), >>
      )
    case let .lineTo(to):
      encode(.lineTo, PathCommand.LineToArgs.self, to, >>)
    case let .appendRectangle(rect):
      encode(.appendRectangle, PathCommand.AppendRectangleArgs.self, rect, >>)
    case let .appendRoundedRect(rect, rx, ry):
      encode(
        .appendRoundedRect,
        PathCommand.AppendRoundedRectArgs.self,
        (rect, rx: rx, ry: ry), >>
      )
    case let .addEllipse(rect):
      encode(.addEllipse, PathCommand.AddEllipseArgs.self, rect, >>)
    case let .addArc(center, radius, startAngle, endAngle, clockwise):
      encode(
        .addArc,
        PathCommand.AddArcArgs.self,
        (center, radius, startAngle, endAngle, clockwise), >>
      )
    case .closePath:
      encode(.closePath, PathCommand.ClosePathArgs.self, (), >>)
    case .endPath:
      // FIXME: Implement end path
      break

    case let .lines(lines):
      encode(.lines, PathCommand.LinesArgs.self, lines, >>)
    case let .composite(steps):
      generateStepsAsPathCommands(steps: steps, bytecode: &bytecode)
    }
  }

  private static func encodeAsDrawCommand(
    _ segment: PathSegment,
    bytecode: inout Bytecode
  ) {
    func encode<T>(
      _ pathCommand: PathCommand,
      _: T.Type, _ value: T, _ encoder: (T, inout Bytecode) -> Void
    ) {
      DrawCommand(pathCommand) >> bytecode
      encoder(value, &bytecode)
    }

    switch segment {
    case let .moveTo(to):
      encode(.moveTo, PathCommand.MoveToArgs.self, to, >>)
    case let .curveTo(c1, c2, end):
      encode(
        .curveTo,
        PathCommand.CurveToArgs.self,
        BCCubicCurve(control1: c1, control2: c2, to: end), >>
      )
    case let .lineTo(to):
      encode(.lineTo, PathCommand.LineToArgs.self, to, >>)
    case let .appendRectangle(rect):
      encode(.appendRectangle, PathCommand.AppendRectangleArgs.self, rect, >>)
    case let .appendRoundedRect(rect, rx, ry):
      encode(
        .appendRoundedRect,
        PathCommand.AppendRoundedRectArgs.self,
        (rect, rx: rx, ry: ry), >>
      )
    case let .addEllipse(rect):
      encode(.addEllipse, PathCommand.AddEllipseArgs.self, rect, >>)
    case let .addArc(center, radius, startAngle, endAngle, clockwise):
      encode(
        .addArc,
        PathCommand.AddArcArgs.self,
        (center, radius, startAngle, endAngle, clockwise), >>
      )
    case .closePath:
      encode(.closePath, PathCommand.ClosePathArgs.self, (), >>)
    case .endPath:
      // FIXME: Implement end path
      break
    case let .lines(lines):
      encode(.lines, PathCommand.LinesArgs.self, lines, >>)
    case let .composite(steps):
      generateStepsAsDrawCommands(steps: steps, bytecode: &bytecode)
    }
  }
}
