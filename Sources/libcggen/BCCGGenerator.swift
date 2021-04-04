//
// Created by Максим Ефимов on 03.04.2021.
//

import Foundation

private protocol ByteCodable {
  var byteCode: String { get }
}

private let newLine = "\n    "

extension UInt32: ByteCodable {
  var byteCode: String {
    var littleEndian = self.littleEndian
    let count = 4
    let bytePtr = withUnsafePointer(to: &littleEndian) { pointer in
      pointer.withMemoryRebound(to: UInt8.self, capacity: count) { pt in
        UnsafeBufferPointer(start: pt, count: count)
      }
    }
    let byteArr = Array(bytePtr)
    return byteArr.map { byte in
      "\(byte)"
    }.joined(separator: ", ") + ", "
  }
}

extension CGFloat: ByteCodable {
  var byteCode: String {
    Float(self).bitPattern.byteCode
  }
}

extension Bool: ByteCodable {
  var byteCode: String {
    if self {
      return "1, "
    }
    return "0, "
  }
}

extension CGPoint: ByteCodable {
  var byteCode: String {
    x.byteCode + y.byteCode
  }
}

extension Array: ByteCodable where Element: ByteCodable {
  var byteCode: String {
    UInt32(count).byteCode + map { point in
      point.byteCode
    }.joined()
  }
}

extension CGRect: ByteCodable {
  var byteCode: String {
    x.byteCode + y.byteCode + width.byteCode + height.byteCode
  }
}

extension CGPathFillRule: ByteCodable {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension DashPattern: ByteCodable {
  var byteCode: String {
    phase.byteCode + UInt32(lengths.count).byteCode + lengths.byteCode
  }
}

extension CGPathDrawingMode: ByteCodable {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension CGAffineTransform: ByteCodable {
  var byteCode: String {
    a.byteCode + b.byteCode + c.byteCode + d.byteCode + tx.byteCode + ty
      .byteCode
  }
}

extension CGLineJoin: ByteCodable {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension CGLineCap: ByteCodable {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension CGColorRenderingIntent: ByteCodable {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension RGBACGColor: ByteCodable {
  var byteCode: String {
    red.byteCode + green.byteCode + blue.byteCode + alpha.byteCode
  }
}

extension ByteCodable where Self == [(CGFloat, RGBACGColor)] {
  var byteCode: String {
    UInt32(self.count).byteCode + self.map { (v: CGFloat, v2: RGBACGColor) in
      v.byteCode + v2.byteCode
    }.joined()
  }
}

extension Gradient: ByteCodable {
  var byteCode: String {
    locationAndColors.byteCode
  }
}

extension CGSize: ByteCodable {
  var byteCode: String {
    width.byteCode + height.byteCode
  }
}

extension Shadow: ByteCodable {
  var byteCode: String {
    offset.byteCode + blur.byteCode + color.byteCode
  }
}

extension CGBlendMode: ByteCodable {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension CGGradientDrawingOptions: ByteCodable {
  var byteCode: String {
    "\(rawValue), "
  }
}

private func byteCommand(_ code: UInt8, _ args: ByteCodable...) -> String {
  "\(newLine)\(code), " + args.map { arg -> String in
    "\(arg.byteCode)"
  }.joined()
}

extension DrawStep: ByteCodable {
  var byteCode: String {
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
    case .endPath:
      return byteCommand(9)
    case .replacePathWithStrokePath:
      return byteCommand(10)
    case let .lines(lines):
      return byteCommand(11, lines)
    case let .clip(rule):
      return byteCommand(12, rule)
    case let .clipToRect(rect):
      return byteCommand(13, rect)
    case let .dash(pattern):
      return byteCommand(14, pattern)
    case let .fill(rule):
      return byteCommand(15, rule)
    case let .fillEllipse(rect):
      return byteCommand(16, rect)
    case .stroke:
      return byteCommand(17)
    case let .drawPath(mode):
      return byteCommand(18, mode)
    case let .addEllipse(rect):
      return byteCommand(19, rect)
    case let .concatCTM(transform):
      return byteCommand(20, transform)
    case let .flatness(f):
      return byteCommand(21, f)
    case let .lineWidth(width):
      return byteCommand(22, width)
    case let .lineJoinStyle(lineJoin):
      return byteCommand(23, lineJoin)
    case let .lineCapStyle(cap):
      return byteCommand(24, cap)
    case let .colorRenderingIntent(intent):
      return byteCommand(25, intent)
    case let .globalAlpha(alpha):
      return byteCommand(26, alpha)
    case .fillColorSpace:
      return byteCommand(27)
    case .strokeColorSpace:
      return byteCommand(28)
    case let .strokeColor(color):
      return byteCommand(29, color)
    case let .fillColor(color):
      return byteCommand(30, color)
    case let .linearGradient(name, options):
      return byteCommand(31, gradientsIds[name]!, options.startPoint, options.endPoint, options.endPoint)
    case let .radialGradient(name, options):
      return byteCommand(32, gradientsIds[name]!, options.startCenter, options.startRadius, options.endCenter, options.endRadius, options.options)
    case let .linearGradientInlined(gradient, options):
      return byteCommand(33, gradient, options.startPoint, options.endPoint, options.options)
    case let .radialGradientInlined(gradient, options):
      return byteCommand(
        34,
        gradient,
        options.startCenter,
        options.startRadius,
        options.endCenter,
        options.endRadius,
        options.options
      )
    case let .subrouteWithName(name):
      return byteCommand(35, subroutesIds[name]!)
    case let .shadow(shadow):
      return byteCommand(36, shadow)
    case let .blendMode(mode):
      return byteCommand(37, mode)
    case .beginTransparencyLayer:
      return byteCommand(38)
    case .endTransparencyLayer:
      return byteCommand(39)
    case let .composite(steps):
      return byteCommand(40, steps)
    }
  }
}

private var gradientsIds: [String: UInt32] = [:]

private func generateGradients(gradients: [String: Gradient]) -> String {
  var res = "\(UInt32(gradients.count).byteCode)"
  for gradient in gradients {
    let counter = UInt32(gradientsIds.count)
    gradientsIds[gradient.key] = counter
    res += newLine + counter.byteCode + gradient.value.byteCode
  }
  return res
}

private var subroutesIds: [String: UInt32] = [:]

private func generateSubroutes(subroutes: [String: DrawRoute]) -> String {
  var res = "\(UInt32(subroutes.count).byteCode)"
  for subroute in subroutes {
    let counter = UInt32(subroutesIds.count)
    subroutesIds[subroute.key] = counter
    res += newLine + counter.byteCode + subroute.value.byteCode
  }
  return res
}

extension DrawRoute: ByteCodable {
  var byteCode: String {
    """
        // Gradients
        \(generateGradients(gradients: gradients))

        // Subroutes
        \(generateSubroutes(subroutes: subroutes))

        // Steps
        \(steps.byteCode)
    """
  }
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
    \(image.route.byteCode)
    };
    void Draw\(image.name.upperCamelCase)ImageInContext(CGContextRef context) {
      runBytecode(context, &\(bytecodeName), sizeof(\(bytecodeName)));
    }
    """
  }

  func fileEnding() -> String {
    "\(CGGradientDrawingOptions(arrayLiteral: [.drawsAfterEndLocation]).rawValue)"
  }
}
