// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

struct DrawStepToObjcCommandGenerator {
  let uniqIDProvider: () -> String
  let contextVarName: String
  let globalDeviceRGBContextName: String
  let gDeviceRgbContext: ObjcTerm.Expr

  func command(
    step: DrawStep,
    gradients: [String: Gradient],
    subroutes: [String: DrawRoute]
  ) -> [String] {
    switch step {
    case .saveGState:
      return [cmd("SaveGState")]
    case .restoreGState:
      return [cmd("RestoreGState")]
    case let .moveTo(p):
      return [cmd("MoveToPoint", points: [p])]
    case let .curveTo(c1, c2, end):
      return [cmd("AddCurveToPoint", points: [c1, c2, end])]
    case let .lineTo(p):
      return [cmd("AddLineToPoint", points: [p])]
    case .closePath:
      return [cmd("ClosePath")]
    case let .clip(rule):
      switch rule {
      case .winding:
        return [cmd("Clip")]
      case .evenOdd:
        return [cmd("EOClip")]
      @unknown default:
        fatalError()
      }
    case .endPath:
      return []
    case let .flatness(flatness):
      return cmd("CGContextSetFlatness", args: .value(flatness)).render(indent: 2)
    case .fillColorSpace:
      return []
    case let .appendRectangle(rect):
      return cmd("CGContextAddRect", args: .value(rect)).render(indent: 2)
    case .strokeColorSpace:
      return []
    case let .concatCTM(transform):
      return [cmd("ConcatCTM", "CGAffineTransformMake(\(transform.a), \(transform.b), \(transform.c), \(transform.d), \(transform.tx), \(transform.ty))")]
    case let .lineWidth(w):
      return cmd("CGContextSetLineWidth", args: .value(w)).render(indent: 2)
    case let .colorRenderingIntent(intent):
      return [cmd("SetRenderingIntent", intent.objcConstName)]
    case let .linearGradient(name, (startPoint, endPoint, options)):
      let drawing = with(gradient: gradients[name]!) { gradient in
        [
          .stmnt(cmd(
            "CGContextDrawLinearGradient",
            args: gradient, .value(startPoint), .value(endPoint), .value(options)
          )),
        ]
      }
      return drawing.render(indent: 2)
    case let .radialGradient(name, (startCenter, startRadius, endCenter, endRadius, options)):
      let drawing = with(gradient: gradients[name]!) { gradient in
        [
          .stmnt(cmd(
            "CGContextDrawRadialGradient",
            args: gradient, .value(startCenter), .value(startRadius),
            .value(endCenter), .value(endRadius), .value(options)
          )),
        ]
      }
      return drawing.render(indent: 2)
    case let .dash(pattern):
      let args = "\(pattern.phase), \(ObjCGen.cgFloatArray(pattern.lengths)), \(pattern.lengths.count)"
      return [cmd("SetLineDash", args)]
    case let .clipToRect(rect):
      return cmd("CGContextClipToRect", args: .value(rect)).render(indent: 2)
    case .beginTransparencyLayer:
      return cmd("CGContextBeginTransparencyLayer", args: .NULL).render(indent: 2)
    case .endTransparencyLayer:
      return [cmd("EndTransparencyLayer")]
    case let .globalAlpha(a):
      return cmd("CGContextSetAlpha", args: .value(a)).render(indent: 2)
    case let .fill(rule):
      switch rule {
      case .winding:
        return [cmd("FillPath")]
      case .evenOdd:
        return [cmd("EOFillPath")]
      @unknown default:
        fatalError()
      }
    case let .lineJoinStyle(style):
      return [cmd("SetLineJoin", style.objcConstName)]
    case let .lineCapStyle(style):
      return [cmd("SetLineCap", style.objcConstName)]
    case let .subrouteWithName(name):
      return ["  \(subrouteBlockName(subrouteName: name))(\(contextVarName));"]
    case let .strokeColor(color):
      return cmd("CGContextSetStrokeColor", args: .value(color.components)).render(indent: 2)
    case .stroke:
      return [cmd("StrokePath")]
    case let .fillColor(color):
      return cmd("CGContextSetFillColor", args: .value(color.components)).render(indent: 2)
    case let .composite(steps):
      return steps.flatMap {
        command(step: $0, gradients: gradients, subroutes: subroutes)
      }
    case let .blendMode(blendMode):
      return [cmd("SetBlendMode", blendMode.objcConstname)]
    case let .lines(points):
      let (pointsArray, pointsId) =
        ObjcTerm.CDecl.cgPointArray("points_\(uniqIDProvider())", points)
      let lines = cmd("CGContextAddLines", args: pointsId, .value(points.count))
      return pointsArray.render(indent: 2) + lines.render(indent: 2)
    case let .fillEllipse(rect):
      return cmd("CGContextFillEllipseInRect", args: .value(rect))
        .render(indent: 2)
    case let .drawPath(mode):
      return cmd("CGContextDrawPath", args: .value(mode))
        .render(indent: 2)
    case let .addEllipse(in: rect):
      return cmd("CGContextAddEllipseInRect", args: .value(rect))
        .render(indent: 2)
    case .replacePathWithStrokePath:
      return cmd("CGContextReplacePathWithStrokedPath")
        .render(indent: 2)
    case let .appendRoundedRect(rect, rx, ry):
      let (pathInit, path) = ObjcTerm.CDecl.functionCall(
        type: .CGPathRef, id: "roundedRect_\(uniqIDProvider())",
        functionName: "CGPathCreateWithRoundedRect",
        args: .value(rect), .value(rx), .value(ry), .NULL
      )
      let append = cmd("CGContextAddPath", args: path)
      let release = ObjcTerm.Statement.call("CGPathRelease", args: path)
      return pathInit.render(indent: 2) +
        append.render(indent: 2) +
        release.render(indent: 2)
    }
  }

  private func cmd(_ name: String, args: ObjcTerm.Expr...) -> ObjcTerm.Statement {
    return .expr(.call(
      .identifier(name),
      args: [.identifier(contextVarName)] + args
    )
    )
  }

  private func cmd(_ name: String, _ args: String? = nil) -> String {
    let argStr: String
    if let args = args {
      argStr = ", \(args)"
    } else {
      argStr = ""
    }
    return "  CGContext\(name)(\(contextVarName)\(argStr));"
  }

  private func cmd(_ name: String, points: [CGPoint]) -> String {
    return cmd(name, points.map { "(CGFloat)\($0.x), (CGFloat)\($0.y)" }.joined(separator: ", "))
  }

  func with(
    gradient: Gradient,
    _ terms: (ObjcTerm.Expr) -> [ObjcTerm.Statement.BlockItem]
  ) -> ObjcTerm.Statement {
    let locAndColors = gradient.locationAndColors
    let (colors, colorsId) = ObjcTerm.CDecl.cgfloatArray(
      "colors_\(uniqIDProvider())",
      locAndColors.flatMap { $0.1.components }
    )
    let (locations, locationsId) = ObjcTerm.CDecl.cgfloatArray(
      "locations_\(uniqIDProvider())",
      locAndColors.map { $0.0 }
    )
    let (gradDecl, gradId) = ObjcTerm.CDecl.functionCall(
      type: .CGGradientRef,
      id: "grad_\(uniqIDProvider())",
      functionName: "CGGradientCreateWithColorComponents",
      args: gDeviceRgbContext, colorsId, locationsId, .value(locAndColors.count)
    )
    let release = ObjcTerm.Statement.call("CGGradientRelease", args: gradId)
    return .block([
      .decl(colors),
      .decl(locations),
      .decl(gradDecl),
    ] + terms(gradId) + [
      .stmnt(release),
    ])
  }
}

private extension CGBlendMode {
  var objcConstname: String {
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

extension CGLineCap {
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

extension CGLineJoin {
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

extension CGColorRenderingIntent {
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

extension CGPathDrawingMode {
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
    return .stmnt(.for(
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
    return .expr(.call(.identifier(name), args: args)
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
    return .init(
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
    return (
      .init(
        specifiers: [.type(.simple(type))],
        declarators: [
          .declinit(
            .init(identifier: id),
            .expr(.call(.identifier(functionName), args: args))
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
    return .init(
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
    return .const(raw: value.description)
  }

  static func value(_ value: CGFloat) -> ObjcTerm.Expr {
    return .cast(to: .CGFloat, .const(raw: value.description))
  }

  static func value(_ cgfloats: [CGFloat]) -> ObjcTerm.Expr {
    return .array(of: .CGFloat, cgfloats.map(value))
  }

  static func value(_ value: CGPoint) -> ObjcTerm.Expr {
    return .list(.CGPoint, [
      .member("x", .value(value.x)),
      .member("y", .value(value.y)),
    ])
  }

  static func value(_ value: CGSize) -> ObjcTerm.Expr {
    return .list(.CGSize, [
      .member("width", .value(value.width)),
      .member("height", .value(value.height)),
    ])
  }

  static func value(_ value: CGRect) -> ObjcTerm.Expr {
    return .list(.CGRect, [
      .member("origin", .value(value.origin)),
      .member("size", .value(value.size)),
    ])
  }

  static func value(_ value: CGPathDrawingMode) -> ObjcTerm.Expr {
    return .identifier(value.objcConstName)
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

  static func incr(_ variable: String) -> ObjcTerm.Expr {
    return .postfix(e: .identifier(variable), op: .incr)
  }

  static let NULL = ObjcTerm.Expr.identifier("NULL")

  static func <(lhs: ObjcTerm.Expr, rhs: ObjcTerm.Expr) -> ObjcTerm.Expr {
    return .bin(lhs: lhs, op: .less, rhs: rhs)
  }

  static func |(lhs: ObjcTerm.Expr, rhs: ObjcTerm.Expr) -> ObjcTerm.Expr {
    return .bin(lhs: lhs, op: .bitwiseOr, rhs: rhs)
  }

  subscript(_ e: ObjcTerm.Expr) -> ObjcTerm.Expr {
    return .subscript(self, idx: e)
  }
}

extension ObjcTerm.TypeIdentifier {
  #if compiler(<5.1)
    public typealias `Self` = ObjcTerm.TypeIdentifier
  #endif
  public static let CGPoint: Self = "CGPoint"
  public static let CGRect: Self = "CGRect"
  public static let CGFloat: Self = "CGFloat"
  public static let CGSize: Self = "CGSize"
  public static let CGContextRef: Self = "CGContextRef"
  public static let CGPathRef: Self = "CGPathRef"
  public static let CGGradientRef: Self = "CGGradientRef"
  public static let CGGradientDrawingOptions: Self = "CGGradientDrawingOptions"
}
