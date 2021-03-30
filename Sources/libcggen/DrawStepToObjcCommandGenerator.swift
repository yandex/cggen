import Foundation

import Base

struct DrawStepToObjcCommandGenerator {
  let uniqIDProvider: () -> String
  let contextVarName: String
  let globalDeviceRGBContextName: String
  let gDeviceRgbContext: ObjcTerm.Expr

  func command(
    step: DrawStep,
    gradients: [String: Gradient],
    subroutes: [String: DrawRoute]
  ) -> ObjcTerm.Statement? {
    switch step {
    case .saveGState:
      return cmd("CGContextSaveGState")
    case .restoreGState:
      return cmd("CGContextRestoreGState")
    case let .moveTo(p):
      return cmd("CGContextMoveToPoint", args: .value(p.x), .value(p.y))
    case let .curveTo(c1, c2, end):
      return cmd(
        "CGContextAddCurveToPoint",
        args: .value(c1.x), .value(c1.y), .value(c2.x), .value(c2.y),
        .value(end.x), .value(end.y)
      )
    case let .lineTo(p):
      return cmd("CGContextAddLineToPoint", args: .value(p.x), .value(p.y))
    case .closePath:
      return cmd("CGContextClosePath")
    case let .clip(rule):
      switch rule {
      case .winding:
        return cmd("CGContextClip")
      case .evenOdd:
        return cmd("CGContextEOClip")
      @unknown default:
        fatalError()
      }
    case .endPath:
      return nil
    case let .flatness(flatness):
      return cmd("CGContextSetFlatness", args: .value(flatness))
    case .fillColorSpace:
      return nil
    case let .appendRectangle(rect):
      return cmd("CGContextAddRect", args: .value(rect))
    case .strokeColorSpace:
      return nil
    case let .concatCTM(transform):
      let affineTransform = ObjcTerm.Expr.call(
        .identifier("CGAffineTransformMake"),
        args: [
          .value(transform.a),
          .value(transform.b),
          .value(transform.c),
          .value(transform.d),
          .value(transform.tx),
          .value(transform.ty),
        ]
      )
      return cmd("CGContextConcatCTM", args: affineTransform)
    case let .lineWidth(w):
      return cmd("CGContextSetLineWidth", args: .value(w))
    case let .colorRenderingIntent(intent):
      return cmd("CGContextSetRenderingIntent", args: .value(intent))
    case let .linearGradient(name, opts):
      return drawLinearGradient(gradients[name]!, options: opts)
    case let .radialGradient(name, opts):
      return drawRadialGradient(gradients[name]!, options: opts)
    case let .linearGradientInlined(grad, opts):
      return drawLinearGradient(grad, options: opts)
    case let .radialGradientInlined(grad, opts):
      return drawRadialGradient(grad, options: opts)
    case let .dash(pattern):
      return cmd(
        "CGContextSetLineDash",
        args: .value(pattern.phase), .value(pattern.lengths), .value(pattern.lengths.count)
      )
    case let .clipToRect(rect):
      return cmd("CGContextClipToRect", args: .value(rect))
    case .beginTransparencyLayer:
      return cmd("CGContextBeginTransparencyLayer", args: .NULL)
    case .endTransparencyLayer:
      return cmd("CGContextEndTransparencyLayer")
    case let .globalAlpha(a):
      return cmd("CGContextSetAlpha", args: .value(a))
    case let .fill(rule):
      switch rule {
      case .winding:
        return cmd("CGContextFillPath")
      case .evenOdd:
        return cmd("CGContextEOFillPath")
      @unknown default:
        fatalError()
      }
    case let .lineJoinStyle(style):
      return cmd("CGContextSetLineJoin", args: .value(style))
    case let .lineCapStyle(style):
      return cmd("CGContextSetLineCap", args: .value(style))
    case let .subrouteWithName(name):
      return cmd(subrouteBlockName(subrouteName: name))
    case let .strokeColor(color):
      return cmd("CGContextSetStrokeColor", args: .value(color.components))
    case .stroke:
      return cmd("CGContextStrokePath")
    case let .fillColor(color):
      return cmd("CGContextSetFillColor", args: .value(color.components))
    case let .composite(steps):
      return .multiple(steps.compactMap {
        command(step: $0, gradients: gradients, subroutes: subroutes)
      })
    case let .blendMode(blendMode):
      return cmd("CGContextSetBlendMode", args: .value(blendMode))
    case let .lines(points):
      return cmd("CGContextAddLines", args: .value(points), .value(points.count))
    case let .fillEllipse(rect):
      return cmd("CGContextFillEllipseInRect", args: .value(rect))
    case let .drawPath(mode):
      return cmd("CGContextDrawPath", args: .value(mode))
    case let .addEllipse(in: rect):
      return cmd("CGContextAddEllipseInRect", args: .value(rect))
    case .replacePathWithStrokePath:
      return cmd("CGContextReplacePathWithStrokedPath")
    case let .appendRoundedRect(rect, rx, ry):
      let (pathInit, path) = ObjcTerm.CDecl.functionCall(
        type: .CGPathRef, id: "roundedRect_\(uniqIDProvider())",
        functionName: "CGPathCreateWithRoundedRect",
        args: .value(rect), .value(rx), .value(ry), .NULL
      )
      let append = cmd("CGContextAddPath", args: path)
      let release = ObjcTerm.Statement.call("CGPathRelease", args: path)
      return .block([
        .decl(pathInit),
        .stmnt(append),
        .stmnt(release),
      ])
    case let .shadow(shadow):
      let (getCtm, ctm) = ObjcTerm.CDecl.functionCall(
        type: .CGAffineTransform, id: "ctm",
        functionName: "CGContextGetCTM", args: .identifier(contextVarName)
      )
      let (getOffset, offset) = ObjcTerm.CDecl.functionCall(
        type: .CGSize, id: "offset_\(uniqIDProvider())",
        functionName: "CGSizeApplyAffineTransform",
        args: .value(shadow.offset), ctm
      )
      let a = ObjcTerm.Expr.cast(to: .double, .member(ctm, "a"))
      let c = ObjcTerm.Expr.cast(to: .double, .member(ctm, "c"))
      let scaleX = ObjcTerm.Expr.call(.identifier("sqrt"), args: [a * a + c * c])
      let blurExpression = ObjcTerm.Expr.cast(
        to: .CGFloat,
        .call(
          .identifier("floor"),
          args: [.value(shadow.blur) * scaleX + .const(raw: "0.5")]
        )
      )
      let (getBlur, blur) = ObjcTerm.CDecl.expression(
        type: .CGFloat, id: "blur_\(uniqIDProvider())",
        expr: blurExpression
      )
      let color = shadow.color
      let (colorInit, colorVar) = ObjcTerm.CDecl.functionCall(
        type: .CGColorRef, id: "color_\(uniqIDProvider())",
        functionName: "CGColorCreate",
        args:
        .identifier(globalDeviceRGBContextName),
        .array(
          of: .CGFloat,
          [color.red, color.green, color.blue, color.alpha].map(ObjcTerm.Expr.value)
        )
      )
      let setShadow = cmd(
        "CGContextSetShadowWithColor",
        args: offset, blur, colorVar
      )
      let release = ObjcTerm.Statement.call("CGColorRelease", args: colorVar)
      return .block([
        .decl(colorInit),
        .decl(getCtm),
        .decl(getOffset),
        .decl(getBlur),
        .stmnt(setShadow),
        .stmnt(release),
      ])
    case let .addArc(center, radius, startAngle, endAngle, clockwise):
      return cmd(
        "CGContextAddArc",
        args: .value(center.x), .value(center.y), .value(radius),
        .value(startAngle), .value(endAngle), .value(clockwise)
      )
    }
  }

  private func cmd(_ name: String, args: ObjcTerm.Expr...) -> ObjcTerm.Statement {
    .expr(.call(
      .identifier(name),
      args: [.identifier(contextVarName)] + args
    )
    )
  }

  private func with(
    gradient: Gradient,
    _ terms: (ObjcTerm.Expr) -> ObjcTerm.Statement.BlockItem
  ) -> ObjcTerm.Statement {
    let locAndColors = gradient.locationAndColors
    let (gradDecl, gradId) = ObjcTerm.CDecl.functionCall(
      type: .CGGradientRef,
      id: "grad_\(uniqIDProvider())",
      functionName: "CGGradientCreateWithColorComponents",
      args: gDeviceRgbContext,
      .value(locAndColors.flatMap { $0.1.components }),
      .value(locAndColors.map { $0.0 }),
      .value(locAndColors.count)
    )
    let release = ObjcTerm.Statement.call("CGGradientRelease", args: gradId)
    return .block([
      .decl(gradDecl),
      terms(gradId),
      .stmnt(release),
    ])
  }

  private func drawLinearGradient(
    _ grad: Gradient,
    options opts: DrawStep.LinearGradientDrawingOptions
  ) -> ObjcTerm.Statement {
    with(gradient: grad) { gradient in
      .stmnt(cmd(
        "CGContextDrawLinearGradient",
        args: gradient,
        .value(opts.startPoint), .value(opts.endPoint), .value(opts.options)
      ))
    }
  }

  private func drawRadialGradient(
    _ grad: Gradient,
    options opts: DrawStep.RadialGradientDrawingOptions
  ) -> ObjcTerm.Statement {
    with(gradient: grad) { gradient in
      .stmnt(cmd(
        "CGContextDrawRadialGradient",
        args: gradient, .value(opts.startCenter), .value(opts.startRadius),
        .value(opts.endCenter), .value(opts.endRadius), .value(opts.options)
      ))
    }
  }
}

private protocol ObjcConstNameExpressible {
  associatedtype Dummy = Self
  var objcConstName: String { get }
}

extension CGBlendMode: ObjcConstNameExpressible {
  var objcConstName: String {
    switch self {
    case .normal:
      return "kCGBlendModeNormal"
    case .multiply:
      return "kCGBlendModeMultiply"
    case .screen:
      return "kCGBlendModeScreen"
    case .overlay:
      return "kCGBlendModeOverlay"
    case .darken:
      return "kCGBlendModeDarken"
    case .lighten:
      return "kCGBlendModeLighten"
    case .colorDodge:
      return "kCGBlendModeColorDodge"
    case .colorBurn:
      return "kCGBlendModeColorBurn"
    case .softLight:
      return "kCGBlendModeSoftLight"
    case .hardLight:
      return "kCGBlendModeHardLight"
    case .difference:
      return "kCGBlendModeDifference"
    case .exclusion:
      return "kCGBlendModeExclusion"
    case .hue:
      return "kCGBlendModeHue"
    case .saturation:
      return "kCGBlendModeSaturation"
    case .color:
      return "kCGBlendModeColor"
    case .luminosity:
      return "kCGBlendModeLuminosity"
    case .clear:
      return "kCGBlendModeClear"
    case .copy:
      return "kCGBlendModeCopy"
    case .sourceIn:
      return "kCGBlendModeSourceIn"
    case .sourceOut:
      return "kCGBlendModeSourceOut"
    case .sourceAtop:
      return "kCGBlendModeSourceAtop"
    case .destinationOver:
      return "kCGBlendModeDestinationOver"
    case .destinationIn:
      return "kCGBlendModeDestinationIn"
    case .destinationOut:
      return "kCGBlendModeDestinationOut"
    case .destinationAtop:
      return "kCGBlendModeDestinationAtop"
    case .xor:
      return "kCGBlendModeXOR"
    case .plusDarker:
      return "kCGBlendModePlusDarker"
    case .plusLighter:
      return "kCGBlendModePlusLighter"
    @unknown default:
      fatalError("Uknown CGBlendMode \(self)")
    }
  }
}

extension CGLineCap: ObjcConstNameExpressible {
  var objcConstName: String {
    switch self {
    case .butt:
      return "kCGLineCapButt"
    case .round:
      return "kCGLineCapRound"
    case .square:
      return "kCGLineCapSquare"
    @unknown default:
      fatalError("Uknown CGLineCap \(self)")
    }
  }
}

extension CGLineJoin: ObjcConstNameExpressible {
  var objcConstName: String {
    switch self {
    case .bevel:
      return "kCGLineJoinBevel"
    case .miter:
      return "kCGLineJoinMiter"
    case .round:
      return "kCGLineJoinRound"
    @unknown default:
      fatalError("Uknown CGLineJoin \(self)")
    }
  }
}

extension CGColorRenderingIntent: ObjcConstNameExpressible {
  var objcConstName: String {
    switch self {
    case .absoluteColorimetric:
      return "kCGRenderingIntentAbsoluteColorimetric"
    case .defaultIntent:
      return "kCGRenderingIntentDefault"
    case .perceptual:
      return "kCGRenderingIntentPerceptual"
    case .relativeColorimetric:
      return "kCGRenderingIntentRelativeColorimetric"
    case .saturation:
      return "kCGRenderingIntentSaturation"
    @unknown default:
      fatalError("Uknown CGColorRenderingIntent \(self)")
    }
  }
}

extension CGPathDrawingMode: ObjcConstNameExpressible {
  var objcConstName: String {
    switch self {
    case .fill:
      return "kCGPathFill"
    case .eoFill:
      return "kCGPathEOFill"
    case .stroke:
      return "kCGPathStroke"
    case .fillStroke:
      return "kCGPathFillStroke"
    case .eoFillStroke:
      return "kCGPathEOFillStroke"
    @unknown default:
      fatalError()
    }
  }
}

extension ObjcTerm {
  static func forLoop(idx: String, range: Range<Int>, body: ObjcTerm.Statement) -> ObjcTerm {
    .stmnt(.for(
      init: .variable(type: .int, name: idx, value: "\(range.lowerBound)"),
      cond: .identifier(idx) < .const(raw: "\(range.upperBound)"),
      incr: .incr(idx),
      body: body
    )
    )
  }
}

extension ObjcTerm.Statement {
  static func call(_ name: String, args: ObjcTerm.Expr...) -> ObjcTerm.Statement {
    .expr(.call(.identifier(name), args: args)
    )
  }
}

extension ObjcTerm.CDecl {
  static func cgPointArray(
    _ name: String,
    _ values: [CGPoint]
  ) -> (ObjcTerm.CDecl, ObjcTerm.Expr) {
    return (
      .array(name, of: .CGPoint, values.map(ObjcTerm.Expr.value)),
      .identifier(name)
    )
  }

  static func cgfloatArray(
    _ name: String,
    _ values: [CGFloat]
  ) -> (ObjcTerm.CDecl, ObjcTerm.Expr) {
    return (
      .array(name, of: .CGFloat, values.map(ObjcTerm.Expr.value)),
      .identifier(name)
    )
  }

  static func variable(type: ObjcTerm.TypeIdentifier, name: String, value: String) -> ObjcTerm.CDecl {
    .init(
      specifiers: [.type(.simple(type))],
      declarators: [
        .declinit(.identifier(name), .expr(ObjcTerm.Expr.const(raw: value))),
      ]
    )
  }

  static func functionCall(
    type: ObjcTerm.TypeIdentifier,
    id: String,
    functionName: String,
    args: ObjcTerm.Expr...
  ) -> (ObjcTerm.CDecl, ObjcTerm.Expr) {
    expression(
      type: type,
      id: id,
      expr: .call(.identifier(functionName), args: args)
    )
  }

  static func expression(
    type: ObjcTerm.TypeIdentifier,
    id: String,
    expr: ObjcTerm.Expr
  ) -> (ObjcTerm.CDecl, ObjcTerm.Expr) {
    return (
      .init(
        specifiers: [.type(.simple(type))],
        declarators: [
          .declinit(
            .init(identifier: id),
            .expr(expr)
          ),
        ]
      ),
      .identifier(id)
    )
  }

  static func array(
    _ name: String,
    of type: ObjcTerm.TypeIdentifier,
    _ values: [ObjcTerm.Expr]
  ) -> ObjcTerm.CDecl {
    .init(
      specifiers: [.type(.simple(type))],
      declarators: [
        .declinit(
          .init(
            pointer: nil,
            direct: .array(.identifier(name)),
            attrs: []
          ), ObjcTerm.CDecl.Initializer.list(values)
        ),
      ]
    )
  }
}

extension ObjcTerm.Expr {
  static func value(_ value: Int) -> ObjcTerm.Expr {
    .const(raw: value.description)
  }

  static func value(_ value: CGFloat) -> ObjcTerm.Expr {
    .cast(to: .CGFloat, .const(raw: value.description))
  }

  static func value(_ cgfloats: [CGFloat]) -> ObjcTerm.Expr {
    .array(of: .CGFloat, cgfloats.map(value))
  }

  static func value(_ value: CGPoint) -> ObjcTerm.Expr {
    .list(.CGPoint, [
      .memberInit("x", .value(value.x)),
      .memberInit("y", .value(value.y)),
    ])
  }

  static func value(_ values: [CGPoint]) -> ObjcTerm.Expr {
    .array(of: .CGPoint, values.map(value))
  }

  static func value(_ value: CGSize) -> ObjcTerm.Expr {
    .list(.CGSize, [
      .memberInit("width", .value(value.width)),
      .memberInit("height", .value(value.height)),
    ])
  }

  static func value(_ value: CGRect) -> ObjcTerm.Expr {
    .list(.CGRect, [
      .memberInit("origin", .value(value.origin)),
      .memberInit("size", .value(value.size)),
    ])
  }

  fileprivate static func value<T: ObjcConstNameExpressible>(
    _ value: T
  ) -> ObjcTerm.Expr {
    .identifier(value.objcConstName)
  }

  static func value(_ value: CGGradientDrawingOptions) -> ObjcTerm.Expr {
    let before: ObjcTerm.Expr? = value.contains(.drawsBeforeStartLocation) ?
      .identifier("kCGGradientDrawsBeforeStartLocation") : nil
    let after: ObjcTerm.Expr? = value.contains(.drawsAfterEndLocation) ?
      .identifier("kCGGradientDrawsAfterEndLocation") : nil
    let expr: ObjcTerm.Expr
    switch (before, after) {
    case (nil, nil):
      expr = .value(0)
    case let (before?, nil):
      expr = before
    case let (nil, after?):
      expr = after
    case let (before?, after?):
      expr = before | after
    }

    return .cast(to: .CGGradientDrawingOptions, expr)
  }

  static func value(_ value: Bool) -> ObjcTerm.Expr {
    .const(raw: value ? "YES" : "NO")
  }

  static func incr(_ variable: String) -> ObjcTerm.Expr {
    .postfix(e: .identifier(variable), op: .incr)
  }

  static let NULL = ObjcTerm.Expr.identifier("NULL")

  static func <(lhs: ObjcTerm.Expr, rhs: ObjcTerm.Expr) -> ObjcTerm.Expr {
    .bin(lhs: lhs, op: .less, rhs: rhs)
  }

  static func |(lhs: ObjcTerm.Expr, rhs: ObjcTerm.Expr) -> ObjcTerm.Expr {
    .bin(lhs: lhs, op: .bitwiseOr, rhs: rhs)
  }

  static func *(lhs: ObjcTerm.Expr, rhs: ObjcTerm.Expr) -> ObjcTerm.Expr {
    .bin(lhs: lhs, op: .multiply, rhs: rhs)
  }

  static func /(lhs: ObjcTerm.Expr, rhs: ObjcTerm.Expr) -> ObjcTerm.Expr {
    .bin(lhs: lhs, op: .multiply, rhs: rhs)
  }

  static func /(lhs: ObjcTerm.Expr, rhs: Int) -> ObjcTerm.Expr {
    lhs / .const(raw: rhs.description)
  }

  static func +(lhs: ObjcTerm.Expr, rhs: ObjcTerm.Expr) -> ObjcTerm.Expr {
    .bin(lhs: lhs, op: .addition, rhs: rhs)
  }

  subscript(_ e: ObjcTerm.Expr) -> ObjcTerm.Expr {
    .subscript(self, idx: e)
  }
}

extension ObjcTerm.TypeIdentifier {
  public static let CGPoint: Self = "CGPoint"
  public static let CGRect: Self = "CGRect"
  public static let CGFloat: Self = "CGFloat"
  public static let CGSize: Self = "CGSize"
  public static let CGColorRef: Self = "CGColorRef"
  public static let CGContextRef: Self = "CGContextRef"
  public static let CGPathRef: Self = "CGPathRef"
  public static let CGGradientRef: Self = "CGGradientRef"
  public static let CGGradientDrawingOptions: Self = "CGGradientDrawingOptions"
  public static let CGAffineTransform: Self = "CGAffineTransform"
}
