//
// Created by Максим Ефимов on 03.04.2021.
//

import Foundation

private protocol ByteCodable {
  var byteCode: [UInt8] { get }
}

extension UInt32: ByteCodable {
  var byteCode: [UInt8] {
    var littleEndian = self.littleEndian
    let count = 4
    let bytePtr = withUnsafePointer(to: &littleEndian) { pointer in
      pointer.withMemoryRebound(to: UInt8.self, capacity: count) { pt in
        UnsafeBufferPointer(start: pt, count: count)
      }
    }
    return Array(bytePtr)
  }
}

extension CGFloat: ByteCodable {
  var byteCode: [UInt8] {
    Float(self).bitPattern.byteCode
  }
}

extension Bool: ByteCodable {
  var byteCode: [UInt8] {
    if self {
      return [1]
    }
    return [0]
  }
}

extension CGPoint: ByteCodable {
  var byteCode: [UInt8] {
    x.byteCode + y.byteCode
  }
}

extension Array: ByteCodable where Element: ByteCodable {
  var byteCode: [UInt8] {
    UInt32(count).byteCode + map { element in
      element.byteCode
    }.joined()
  }
}

extension CGRect: ByteCodable {
  var byteCode: [UInt8] {
    x.byteCode + y.byteCode + width.byteCode + height.byteCode
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
    let abcd = a.byteCode + b.byteCode + c.byteCode + d.byteCode
    return abcd + tx.byteCode + ty.byteCode
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

extension RGBACGColor: ByteCodable {
  var byteCode: [UInt8] {
    red.byteCode + green.byteCode + blue.byteCode + alpha.byteCode
  }
}

extension ByteCodable where Self == [(CGFloat, RGBACGColor)] {
  var byteCode: [UInt8] {
    UInt32(self.count).byteCode + self.map { (v: CGFloat, v2: RGBACGColor) in
      v.byteCode + v2.byteCode
    }.joined()
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

private func byteCommand(_ code: UInt8, _ args: ByteCodable...) -> [UInt8] {
  [code] + args.map { arg -> [UInt8] in
    arg.byteCode
  }.joined()
}

private func generateSteps(steps: [DrawStep]) -> [UInt8] {
  Array(steps.map{ step in step.byteCode}.joined())
}

extension DrawStep: ByteCodable {
  var byteCode: [UInt8] {
    switch self {
    case .saveGState:
      return byteCommand(0)
    case .restoreGState:
      return byteCommand(1)
    case let .moveTo(to):
      return byteCommand(2, to)
    case let .curveTo(c1, c2, end):
      return byteCommand(3, c1, c2, end)
    case let .lineTo(to):
      return byteCommand(4, to)
    case let .appendRectangle(rect):
      return byteCommand(5, rect)
    case let .appendRoundedRect(rect, rx, ry):
      return byteCommand(6, rect, rx, ry)
    case let .addArc(center, radius, startAngle, endAngle, clockwise):
      return byteCommand(7, center, radius, startAngle, endAngle, clockwise)
    case .closePath:
      return byteCommand(8)
    case .replacePathWithStrokePath:
      return byteCommand(9)
    case let .lines(lines):
      return byteCommand(10, lines)
    case let .clip(rule):
      return byteCommand(11, rule)
    case let .clipToRect(rect):
      return byteCommand(12, rect)
    case let .dash(pattern):
      return byteCommand(13, pattern)
    case let .fill(rule):
      return byteCommand(14, rule)
    case let .fillEllipse(rect):
      return byteCommand(15, rect)
    case .stroke:
      return byteCommand(16)
    case let .drawPath(mode):
      return byteCommand(17, mode)
    case let .addEllipse(rect):
      return byteCommand(18, rect)
    case let .concatCTM(transform):
      return byteCommand(19, transform)
    case let .flatness(f):
      return byteCommand(20, f)
    case let .lineWidth(width):
      return byteCommand(21, width)
    case let .lineJoinStyle(lineJoin):
      return byteCommand(22, lineJoin)
    case let .lineCapStyle(cap):
      return byteCommand(23, cap)
    case let .colorRenderingIntent(intent):
      return byteCommand(24, intent)
    case let .globalAlpha(alpha):
      return byteCommand(25, alpha)
    case let .strokeColor(color):
      return byteCommand(26, color)
    case let .fillColor(color):
      return byteCommand(27, color)
    case let .linearGradient(name, options):
      return byteCommand(
        28,
        gradientsIds[name]!,
        options.startPoint,
        options.endPoint,
        options.endPoint
      )
    case let .radialGradient(name, options):
      return byteCommand(
        29,
        gradientsIds[name]!,
        options.startCenter,
        options.startRadius,
        options.endCenter,
        options.endRadius,
        options.options
      )
    case let .linearGradientInlined(gradient, options):
      return byteCommand(
        30,
        gradient,
        options.startPoint,
        options.endPoint,
        options.options
      )
    case let .radialGradientInlined(gradient, options):
      return byteCommand(
        31,
        gradient,
        options.startCenter,
        options.startRadius,
        options.endCenter,
        options.endRadius,
        options.options
      )
    case let .subrouteWithName(name):
      return byteCommand(32, subroutesIds[name]!)
    case let .shadow(shadow):
      return byteCommand(33, shadow)
    case let .blendMode(mode):
      return byteCommand(34, mode)
    case .beginTransparencyLayer:
      return byteCommand(35)
    case .endTransparencyLayer:
      return byteCommand(36)
    case let .composite(steps):
      return generateSteps(steps: steps)
    case .endPath, .fillColorSpace, .strokeColorSpace:
      return []
    }
  }
}

extension DrawRoute: ByteCodable {
  var byteCode: [UInt8] {
    generateGradients(gradients: gradients) +
      generateSubroutes(subroutes: subroutes) + generateSteps(steps: steps)
  }
}

private var gradientsIds: [String: UInt32] = [:]

private func generateGradients(gradients: [String: Gradient]) -> [UInt8] {
  var res = UInt32(gradients.count).byteCode
  for gradient in gradients {
    let counter = UInt32(gradientsIds.count)
    gradientsIds[gradient.key] = counter
    res += counter.byteCode + gradient.value.byteCode
  }
  return res
}

private var subroutesIds: [String: UInt32] = [:]

private func generateSubroutes(subroutes: [String: DrawRoute]) -> [UInt8] {
  var res = UInt32(subroutes.count).byteCode
  for subroute in subroutes {
    let counter = UInt32(subroutesIds.count)
    subroutesIds[subroute.key] = counter
    let subrouteBytecode = subroute.value.byteCode
    res += counter.byteCode + UInt32(subrouteBytecode.count)
      .byteCode + subrouteBytecode
  }
  return res
}

struct BCCGGenerator: CoreGraphicsGenerator {
  let headerImportPath: String

  func filePreamble() -> String {
    """
    #import <CoreGraphics/CoreGraphics.h>
    #import "\(headerImportPath)"
    @import BCRunner;
    typedef const unsigned char bytecode;
    void runBytecode(CGContextRef context, bytecode** arr, int len);
    """
  }

  func generateImageFunction(image: Image) -> String {
    let bytecodeName = "\(image.name)Bytecode"
    return """
    bytecode \(bytecodeName)[] = {
    \(image.route.byteCode.map { byte -> String in "\(byte), " }.joined())
    };
    void Draw\(image.name.upperCamelCase)ImageInContext(CGContextRef context) {
      runBytecode(context, &\(bytecodeName), sizeof(\(bytecodeName)));
    }
    """
  }

  func fileEnding() -> String {
    ""
  }
}
