//
// Created by Максим Ефимов on 03.04.2021.
//

import Foundation

protocol ByteArgument {
  var byteCode: String { get }
}

extension UInt32: ByteArgument {
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

extension CGFloat: ByteArgument {
  var byteCode: String {
    Float(self).bitPattern.byteCode
  }
}

extension Bool: ByteArgument {
  var byteCode: String {
    if self {
      return "1, "
    }
    return "0, "
  }
}

extension CGPoint: ByteArgument {
  var byteCode: String {
    x.byteCode + y.byteCode
  }
}

extension Array: ByteArgument where Element: ByteArgument {
  var byteCode: String {
    UInt32(count).byteCode + map { point in
      point.byteCode
    }.joined()
  }
}

extension CGRect: ByteArgument {
  var byteCode: String {
    x.byteCode + y.byteCode + width.byteCode + height.byteCode
  }
}

extension CGPathFillRule: ByteArgument {
  var byteCode: String {
    switch self {
    case .evenOdd:
      return "0, "
    case .winding:
      return "1, "
    @unknown default:
      fatalError("unsupported rule")
    }
  }
}

extension DashPattern: ByteArgument {
  var byteCode: String {
    phase.byteCode + UInt32(lengths.count).byteCode + lengths.byteCode
  }
}

extension CGPathDrawingMode: ByteArgument {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension CGAffineTransform: ByteArgument {
  var byteCode: String {
    a.byteCode + b.byteCode + c.byteCode + d.byteCode + tx.byteCode + ty
      .byteCode
  }
}

extension CGLineJoin: ByteArgument {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension CGLineCap: ByteArgument {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension CGColorRenderingIntent: ByteArgument {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension RGBACGColor: ByteArgument {
  var byteCode: String {
    red.byteCode + green.byteCode + blue.byteCode + alpha.byteCode
  }
}

extension ByteArgument where Self == [(CGFloat, RGBACGColor)] {
  var byteCode: String {
    UInt32(self.count).byteCode + self.map { (v: CGFloat, v2: RGBACGColor) in
      v.byteCode + v2.byteCode
    }.joined()
  }
}

extension Gradient: ByteArgument {
  var byteCode: String {
    locationAndColors.byteCode
  }
}

extension CGSize: ByteArgument {
  var byteCode: String {
    width.byteCode + height.byteCode
  }
}

extension Shadow: ByteArgument {
  var byteCode: String {
    offset.byteCode + blur.byteCode + color.byteCode
  }
}

extension CGBlendMode: ByteArgument {
  var byteCode: String {
    "\(rawValue), "
  }
}

extension DrawStep: ByteArgument {
  var byteCode: String {
    stepToByteCode(self)
  }
}

private func byteCommand(_ code: UInt8, _ args: ByteArgument...) -> String {
  "\n    \(code), " + args.map { arg -> String in
    "\(arg.byteCode)"
  }.joined()
}

private func stepToByteCode(_ step: DrawStep) -> String {
  switch step {
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
  case .linearGradient:
    return "UNSUPPORTED"
  case .radialGradient:
    return "UNSUPPORTED"
  case let .linearGradientInlined(gradient, options):
    return byteCommand(33, gradient, options.startPoint, options.endPoint)
  case let .radialGradientInlined(gradient, options):
    return byteCommand(
      34,
      gradient,
      options.startCenter,
      options.startRadius,
      options.endCenter,
      options.endRadius
    )
  case .subrouteWithName:
    return "UNSUPPORTED"
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

private func f(steps: [DrawStep]) -> String {
  steps.map(stepToByteCode).joined(separator: "")
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
    bytecode \(bytecodeName)[] = {\(f(steps: image.route.steps))
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
