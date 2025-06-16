import CoreGraphics
import Foundation

import Base
import CGGen
import PDFParse

private enum PDFGradientDrawingOptions {
  case linear(DrawStep.LinearGradientDrawingOptions)
  case radial(DrawStep.RadialGradientDrawingOptions)
}

enum PDFToDrawRouteConverter {
  static func convert(xobject: PDFXObject) throws -> DrawRoutine {
    let ctm = xobject.matrix ?? .identity
    let bbox = xobject.bbox
    var prepend: [DrawStep] = [.saveGState, .concatCTM(ctm), .clipToRect(bbox)]
    var append: [DrawStep] = [.restoreGState]
    if xobject.group != nil {
      prepend += [
        .fillAlpha(1),
        .strokeAlpha(1),
        .beginTransparencyLayer,
      ]
      append.append(.endTransparencyLayer)
    }
    return try convert(
      resources: xobject.resources,
      bbox: xobject.bbox,
      operators: xobject.operators,
      prependSteps: prepend,
      appendSteps: append
    )
  }

  static func convert(page: PDFPage) throws -> DrawRoutine {
    try convert(
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
  ) throws -> DrawRoutine {
    let gradients = resources.shadings.mapValues { $0.makeGradient() }
    let subroutines = try resources.xObjects
      .mapValues { try convert(xobject: $0) }
    precondition(resources.xObjects.count == subroutines.count)
    let steps = try operatorsToSteps(
      ops: operators,
      resources: resources,
      gradients: gradients.mapValues { $0.1 }
    )
    let route = DrawRoutine(
      boundingRect: bbox,
      gradients: gradients.mapValues { $0.0 },
      subroutines: subroutines,
      steps: prependSteps + steps + appendSteps
    )
    return route
  }

  private static func operatorsToSteps(
    ops: [PDFOperator],
    resources: PDFResources,
    gradients: [String: PDFGradientDrawingOptions]
  ) throws -> [DrawStep] {
    try ops.map {
      try $0.drawStep(
        resources: resources,
        gradients: gradients
      )
    }
  }
}

extension PDFOperator {
  fileprivate func drawStep(
    resources: PDFResources,
    gradients: [String: PDFGradientDrawingOptions]
  ) throws -> DrawStep {
    switch self {
    case .closeFillStrokePathWinding:
      throw DrawError("Not implemented")
    case .fillStrokePathWinding:
      throw DrawError("Not implemented")
    case .closeFillStrokePathEvenOdd:
      throw DrawError("Not implemented")
    case .fillStrokePathEvenOdd:
      throw DrawError("Not implemented")
    case .markedContentSequenceWithPListBegin:
      throw DrawError("Not implemented")
    case .inlineImageBegin:
      throw DrawError("Not implemented")
    case .markedContentSequenceBegin:
      throw DrawError("Not implemented")
    case .textObjectBegin:
      throw DrawError("Not implemented")
    case .compatabilitySectionBegin:
      throw DrawError("Not implemented")
    case let .curveTo(p1, p2, p3):
      return .pathSegment(.curveTo(p1, p2, p3))
    case let .concatCTM(transform):
      return .concatCTM(transform)
    case .colorSpaceStroke:
      return .empty
    case .colorSpaceNonstroke:
      return .empty
    case let .dash(phase, lengths):
      let pattern = DashPattern(phase: phase, lengths: lengths)
      return .dash(pattern)
    case .glyphWidthInType3Font:
      throw DrawError("Not implemented")
    case .glyphWidthAndBoundingBoxInType3Font:
      throw DrawError("Not implemented")
    case let .invokeXObject(name):
      return .composite([
        .saveGState,
        .setGlobalAlphaToFillAlpha,
        .subrouteWithName(name),
        .restoreGState,
      ])
    case .markedContentPointWithPListDefine:
      throw DrawError("Not implemented")
    case .inlineImageEnd:
      throw DrawError("Not implemented")
    case .markedContentSequenceEnd:
      throw DrawError("Not implemented")
    case .textObjectEnd:
      throw DrawError("Not implemented")
    case .compatabilitySectionEnd:
      throw DrawError("Not implemented")
    case .fillWinding:
      return .fillWithRule(.winding)
    case .fillEvenOdd:
      return .fillWithRule(.evenOdd)
    case .grayLevelStroke:
      throw DrawError("Not implemented")
    case .grayLevelNonstroke:
      throw DrawError("Not implemented")
    case let .applyGState(name):
      let state = resources.gStates[name]!
      let steps = try state.commands.map { cmd -> DrawStep in
        switch cmd {
        case let .fillAlpha(alpha):
          return .fillAlpha(alpha)
        case let .strokeAlpha(alpha):
          return .strokeAlpha(alpha)
        case let .blendMode(pdfBlendMode):
          let blendMode = try CGBlendMode(pdfBlendMode: pdfBlendMode)
          return .blendMode(blendMode)
        case .sMask:
          throw DrawError("Soft Mask not implemented")
        }
      }
      return .composite(steps)
    case .closeSubpath:
      return .pathSegment(.closePath)
    case let .setFlatnessTolerance(flatness):
      return .flatness(flatness)
    case .inlineImageDataBegin:
      throw DrawError("Not implemented")
    case let .lineJoinStyle(styleRaw):
      guard let style = CGLineJoin(rawValue: Int32(styleRaw)) else {
        throw DrawError("Unknown line join style: \(styleRaw)")
      }
      return .lineJoinStyle(style)
    case let .lineCapStyle(styleRaw):
      guard let style = CGLineCap(rawValue: Int32(styleRaw)) else {
        throw DrawError("Unknown line cap style: \(styleRaw)")
      }
      return .lineCapStyle(style)
    case .cmykColorStroke:
      throw DrawError("Not implemented")
    case .cmykColorNonstroke:
      throw DrawError("Not implemented")
    case let .lineTo(point):
      return .pathSegment(.lineTo(point))
    case let .moveTo(point):
      return .pathSegment(.moveTo(point))
    case .miterLimit:
      throw DrawError("Not implemented")
    case .markedContentPointDefine:
      throw DrawError("Not implemented")
    case .endPath:
      return .pathSegment(.endPath)
    case .saveGState:
      return .saveGState
    case .restoreGState:
      return .restoreGState
    case let .appendRectangle(rect):
      return .pathSegment(.appendRectangle(rect))
    case let .rgbColorStroke(color):
      return .strokeColor(color)
    case let .rgbColorNonstroke(color):
      return .fillColor(color)
    case let .colorRenderingIntent(name):
      return .colorRenderingIntent(CGColorRenderingIntent(pdfIntent: name))
    case .closeAndStrokePath:
      return .composite([.pathSegment(.closePath), .stroke])
    case .strokePath:
      return .stroke
    case let .colorStroke(color):
      return .strokeColor(color)
    case let .colorNonstroke(color):
      return .fillColor(color)
    case .iccOrSpecialColorStroke:
      throw DrawError("Not implemented")
    case .iccOrSpecialColorNonstroke:
      throw DrawError("Not implemented")
    case let .shadingFill(shading):
      switch gradients[shading] {
      case nil:
        return .empty
      case let .linear(linear)?:
        return .linearGradient(shading, linear)
      case let .radial(radial)?:
        return .radialGradient(shading, radial)
      }
    case .startNextTextLine:
      throw DrawError("Not implemented")
    case .characterSpacing:
      throw DrawError("Not implemented")
    case .moveTextPosition:
      throw DrawError("Not implemented")
    case .moveTextPositionAnsSetLeading:
      throw DrawError("Not implemented")
    case .textFontAndSize:
      throw DrawError("Not implemented")
    case .showText:
      throw DrawError("Not implemented")
    case .showTextAllowingIndividualGlyphPositioning:
      throw DrawError("Not implemented")
    case .textLeading:
      throw DrawError("Not implemented")
    case .textAndTextLineMatrix:
      throw DrawError("Not implemented")
    case .textRenderingMode:
      throw DrawError("Not implemented")
    case .textRise:
      throw DrawError("Not implemented")
    case .wordSpacing:
      throw DrawError("Not implemented")
    case .horizontalTextScaling:
      throw DrawError("Not implemented")
    case .curveToWithInitailPointReplicated:
      throw DrawError("Not implemented")
    case let .lineWidth(w):
      return .lineWidth(w)
    case .clipWinding:
      return .clipWithRule(.winding)
    case .clipEvenOdd:
      return .clipWithRule(.evenOdd)
    case .curveToWithFinalPointReplicated:
      throw DrawError("Not implemented")
    case .moveToNextLineAndShowText:
      throw DrawError("Not implemented")
    case .wordAndCharacterSpacingMoveToNextLineAndShowText:
      throw DrawError("Not implemented")
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

extension CGBlendMode {
  fileprivate init(pdfBlendMode: String) throws {
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
      throw DrawError("Unknown/unimplemented blend mode – '\(pdfBlendMode)'")
    }
  }
}

extension PDFShading {
  fileprivate func makeGradient() -> (Gradient, PDFGradientDrawingOptions) {
    let locationAndColors = function.points
      .map { point -> (CGFloat, RGBACGColor) in
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
    return (Gradient(locationAndColors: locationAndColors), drawingOptions)
  }

  private var function: PDFFunction {
    switch kind {
    case let .axial(axial):
      axial.function
    case let .radial(radial):
      radial.function
    }
  }

  private var extend: PDFShading.Extend {
    switch kind {
    case let .axial(axial):
      axial.extend
    case let .radial(radial):
      radial.extend
    }
  }

  private var startPoint: CGPoint {
    switch kind {
    case let .axial(axial):
      axial.coords.p0
    case let .radial(radial):
      radial.coords.p0
    }
  }

  private var endPoint: CGPoint {
    switch kind {
    case let .axial(axial):
      axial.coords.p1
    case let .radial(radial):
      radial.coords.p1
    }
  }

  private var drawingOptions: PDFGradientDrawingOptions {
    switch kind {
    case let .axial(axial):
      .linear(
        .init(
          startPoint: axial.coords.p0,
          endPoint: axial.coords.p1,
          options: .init(pdfExtend: axial.extend),
          units: .objectBoundingBox
        )
      )
    case let .radial(radial):
      .radial(.init(
        startCenter: radial.coords.p0,
        startRadius: radial.startRadius,
        endCenter: radial.coords.p1,
        endRadius: radial.endRadius,
        options: .init(pdfExtend: radial.extend)
      ))
    }
  }
}

extension CGGradientDrawingOptions {
  init(pdfExtend: PDFShading.Extend) {
    let (before, after) = pdfExtend
    self = []
    if before { insert(.drawsBeforeStartLocation) }
    if after { insert(.drawsAfterEndLocation) }
  }
}

private struct DrawError: Swift.Error {
  init(_ text: String, file: String = #file, line: Int = #line) {
    self.text = text
    self.file = file
    self.line = line
  }

  let text: String
  let file: String
  let line: Int
}
