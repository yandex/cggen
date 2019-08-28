// Copyright (c) 2018 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation
import PDFParse

private class Context {
  private var stack: [Context] = []
  var fillAlpha: CGFloat = 1
  var strokeAlpha: CGFloat = 1
  var fillColor: PDFColor = .black()
  var strokeColor: PDFColor = .black()

  var fillColorWithAlpha: RGBACGColor {
    return fillColor.withAlpha(fillAlpha)
  }

  var strokeColorWithAlpha: RGBACGColor {
    return strokeColor.withAlpha(strokeAlpha)
  }

  func save() {
    stack.append(copy())
  }

  func restore() {
    let restored = stack.removeLast()
    restored.copyStateTo(ctx: self)
  }

  func copy() -> Context {
    let new = Context()
    copyStateTo(ctx: new)
    return new
  }

  private func copyStateTo(ctx: Context) {
    ctx.fillAlpha = fillAlpha
    ctx.strokeAlpha = strokeAlpha
    ctx.fillColor = fillColor
    ctx.strokeColor = strokeColor
  }
}

enum PDFToDrawRouteConverter {
  static func convert(xobject: PDFXObject) -> DrawRoute {
    let ctm = xobject.matrix ?? .identity
    let bbox = xobject.bbox
    var prepend: [DrawStep] = [.saveGState, .concatCTM(ctm), .clipToRect(bbox)]
    var append: [DrawStep] = [.restoreGState]
    if xobject.group != nil {
      prepend.append(.beginTransparencyLayer)
      append.append(.endTransparencyLayer)
    }
    return convert(
      resources: xobject.resources,
      bbox: xobject.bbox,
      operators: xobject.operators,
      prependSteps: prepend,
      appendSteps: append
    )
  }

  static func convert(page: PDFPage) -> DrawRoute {
    return convert(
      resources: page.resources,
      bbox: page.bbox,
      operators: page.operators
    )
  }

  private static func convert(
    resources: PDFResources,
    bbox: CGRect,
    operators: [PDFOperator],
    prependSteps: [DrawStep] = [],
    appendSteps: [DrawStep] = []
  ) -> DrawRoute {
    let gradients = resources.shadings.mapValues { $0.makeGradient() }
    let subroutes = resources.xObjects.mapValues { convert(xobject: $0) }
    precondition(resources.xObjects.count == subroutes.count)
    let steps = operatorsToSteps(ops: operators, resources: resources)
    let route = DrawRoute(
      boundingRect: bbox,
      gradients: gradients,
      subroutes: subroutes,
      steps: prependSteps + steps + appendSteps
    )
    return route
  }

  private static func operatorsToSteps(
    ops: [PDFOperator],
    resources: PDFResources
  ) -> [DrawStep] {
    let context = Context()
    return ops.map { $0.drawStep(resources: resources, context: context) }
  }
}

private extension PDFOperator {
  func drawStep(resources: PDFResources, context: Context) -> DrawStep {
    switch self {
    case .closeFillStrokePathWinding:
      fatalError("Not implemented")
    case .fillStrokePathWinding:
      fatalError("Not implemented")
    case .closeFillStrokePathEvenOdd:
      fatalError("Not implemented")
    case .fillStrokePathEvenOdd:
      fatalError("Not implemented")
    case .markedContentSequenceWithPListBegin:
      fatalError("Not implemented")
    case .inlineImageBegin:
      fatalError("Not implemented")
    case .markedContentSequenceBegin:
      fatalError("Not implemented")
    case .textObjectBegin:
      fatalError("Not implemented")
    case .compatabilitySectionBegin:
      fatalError()

    case let .curveTo(p1, p2, p3):
      return .curveTo(p1, p2, p3)
    case let .concatCTM(transform):
      return .concatCTM(transform)
    case .colorSpaceStroke:
      return .strokeColorSpace
    case .colorSpaceNonstroke:
      return .fillColorSpace
    case let .dash(phase, lengths):
      let pattern = DashPattern(phase: phase, lengths: lengths)
      return .dash(pattern)

    case .glyphWidthInType3Font:
      fatalError("Not implemented")
    case .glyphWidthAndBoundingBoxInType3Font:
      fatalError()

    case let .invokeXObject(name):
      return .composite([
        .globalAlpha(context.fillAlpha),
        .subrouteWithName(name),
      ])

    case .markedContentPointWithPListDefine:
      fatalError("Not implemented")
    case .inlineImageEnd:
      fatalError("Not implemented")
    case .markedContentSequenceEnd:
      fatalError("Not implemented")
    case .textObjectEnd:
      fatalError("Not implemented")
    case .compatabilitySectionEnd:
      fatalError()

    case .fillWinding:
      return .fillWithColor(context: context, rule: .winding)
    case .fillEvenOdd:
      return .fillWithColor(context: context, rule: .evenOdd)

    case .grayLevelStroke:
      fatalError("Not implemented")
    case .grayLevelNonstroke:
      fatalError()

    case let .applyGState(name):
      let state = resources.gStates[name]!
      let steps = state.commands.map { (cmd) -> DrawStep in
        switch cmd {
        case let .fillAlpha(alpha):
          context.fillAlpha = alpha
        case let .strokeAlpha(alpha):
          context.strokeAlpha = alpha
        case let .blendMode(pdfBlendMode):
          let blendMode = CGBlendMode(pdfBlendMode: pdfBlendMode)
          return .blendMode(blendMode)
        case .sMask:
          fatalError("Soft Mask not implemented")
        }
        return .empty
      }
      return .composite(steps)
    case .closeSubpath:
      return .closePath
    case let .setFlatnessTolerance(flatness):
      return .flatness(flatness)

    case .inlineImageDataBegin:
      fatalError("Not implemented")
    case let .lineJoinStyle(styleRaw):
      guard let style = CGLineJoin(rawValue: Int32(styleRaw)) else {
        fatalError("Unknown line join style: \(styleRaw)")
      }
      return .lineJoinStyle(style)
    case let .lineCapStyle(styleRaw):
      guard let style = CGLineCap(rawValue: Int32(styleRaw)) else {
        fatalError("Unknown line cap style: \(styleRaw)")
      }
      return .lineCapStyle(style)

    case .cmykColorStroke:
      fatalError("Not implemented")
    case .cmykColorNonstroke:
      fatalError()

    case let .lineTo(point):
      return .lineTo(point)
    case let .moveTo(point):
      return .moveTo(point)

    case .miterLimit:
      fatalError("Not implemented")
    case .markedContentPointDefine:
      fatalError()

    case .endPath:
      return .endPath
    case .saveGState:
      context.save()
      return .saveGState
    case .restoreGState:
      context.restore()
      return .restoreGState
    case let .appendRectangle(rect):
      return .appendRectangle(rect)
    case let .rgbColorStroke(color):
      context.strokeColor = color
      return .empty
    case let .rgbColorNonstroke(color):
      context.fillColor = color
      return .empty
    case let .colorRenderingIntent(name):
      return .colorRenderingIntent(CGColorRenderingIntent(pdfIntent: name))

    case .closeAndStrokePath:
      return .composite([.closePath, .strokeWithColor(context)])
    case .strokePath:
      return .strokeWithColor(context)
    case let .colorStroke(color):
      context.strokeColor = color
      return .empty
    case let .colorNonstroke(color):
      context.fillColor = color
      return .empty

    case .iccOrSpecialColorStroke:
      fatalError("Not implemented")
    case .iccOrSpecialColorNonstroke:
      fatalError("Not implemented")
    case let .shadingFill(shading):
      return .paintWithGradient(shading, start: nil, end: nil)
    case .startNextTextLine:
      fatalError("Not implemented")
    case .characterSpacing:
      fatalError("Not implemented")
    case .moveTextPosition:
      fatalError("Not implemented")
    case .moveTextPositionAnsSetLeading:
      fatalError("Not implemented")
    case .textFontAndSize:
      fatalError("Not implemented")
    case .showText:
      fatalError("Not implemented")
    case .showTextAllowingIndividualGlyphPositioning:
      fatalError("Not implemented")
    case .textLeading:
      fatalError("Not implemented")
    case .textAndTextLineMatrix:
      fatalError("Not implemented")
    case .textRenderingMode:
      fatalError("Not implemented")
    case .textRise:
      fatalError("Not implemented")
    case .wordSpacing:
      fatalError("Not implemented")
    case .horizontalTextScaling:
      fatalError("Not implemented")
    case .curveToWithInitailPointReplicated:
      fatalError("Not implemented")

    case let .lineWidth(w):
      return .lineWidth(w)
    case .clipWinding:
      return .clip(.winding)
    case .clipEvenOdd:
      return .clip(.evenOdd)

    case .curveToWithFinalPointReplicated:
      fatalError("Not implemented")
    case .moveToNextLineAndShowText:
      fatalError("Not implemented")
    case .wordAndCharacterSpacingMoveToNextLineAndShowText:
      fatalError("Not implemented")
    }
  }
}

extension CGColorRenderingIntent {
  init(pdfIntent: String) {
    switch pdfIntent {
    case "AbsoluteColorimetric":
      self = .absoluteColorimetric
    case "Perceptual":
      self = .perceptual
    case "RelativeColorimetric":
      self = .relativeColorimetric
    case "Saturation":
      self = .saturation
    default:
      assertionFailure("Unknown pdf color rendering intent: \(pdfIntent)")
      self = .defaultIntent
    }
  }
}

private extension CGBlendMode {
  init(pdfBlendMode: String) {
    switch pdfBlendMode {
    case "Normal":
      self = .normal
    case "Multiply":
      self = .multiply
    case "Screen":
      self = .screen
    case "Overlay":
      self = .overlay
    case "Darken":
      self = .darken
    case "Lighten":
      self = .lighten
    case "ColorDodge":
      self = .colorDodge
    case "ColorBurn":
      self = .colorBurn
    case "HardLight":
      self = .hardLight
    case "SoftLight":
      self = .softLight
    case "Difference":
      self = .difference
    case "Exclusion":
      self = .exclusion
    default:
      fatalError("Unknown/unimplemented blend mode – '\(pdfBlendMode)'")
    }
  }
}

private extension PDFShading {
  func makeGradient() -> Gradient {
    let locationAndColors = function.points.map { (point) -> (CGFloat, RGBACGColor) in
      precondition(point.value.count == 3)
      let loc = point.arg
      let components = point.value
      let color = RGBAColor(
        red: components[0],
        green: components[1],
        blue: components[2],
        alpha: 1
      )
      return (loc, color)
    }
    var options: CGGradientDrawingOptions = []
    if extend.0 {
      options.insert(.drawsBeforeStartLocation)
    }
    if extend.1 {
      options.insert(.drawsAfterEndLocation)
    }
    return Gradient(
      locationAndColors: locationAndColors,
      startPoint: startPoint,
      endPoint: endPoint,
      options: options,
      kind: gradientKind
    )
  }

  var function: PDFFunction {
    switch kind {
    case let .axial(axial):
      return axial.function
    case let .radial(radial):
      return radial.function
    }
  }

  var extend: PDFShading.Extend {
    switch kind {
    case let .axial(axial):
      return axial.extend
    case let .radial(radial):
      return radial.extend
    }
  }

  var startPoint: CGPoint {
    switch kind {
    case let .axial(axial):
      return axial.coords.p0
    case let .radial(radial):
      return radial.coords.p0
    }
  }

  var endPoint: CGPoint {
    switch kind {
    case let .axial(axial):
      return axial.coords.p1
    case let .radial(radial):
      return radial.coords.p1
    }
  }

  var gradientKind: Gradient.Kind {
    switch kind {
    case .axial:
      return .axial
    case let .radial(radial):
      return .radial(
        startRadius: radial.startRadius, endRadius: radial.endRadius
      )
    }
  }
}

private extension DrawStep {
  static func fillWithColor(context: Context, rule: CGPathFillRule) -> DrawStep {
    return .composite([
      .fillColor(context.fillColorWithAlpha),
      .fill(rule),
    ])
  }

  static func strokeWithColor(_ context: Context) -> DrawStep {
    return .composite([
      .strokeColor(context.strokeColorWithAlpha),
      .stroke,
    ])
  }
}
