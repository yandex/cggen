import CoreGraphics
import Foundation

import BCCommon

protocol BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> Self
}

extension BytecodeElement where Self: FixedWidthInteger {
  internal static func readFrom(_ runner: BytecodeRunner) -> Self {
    runner.readInt()
  }
}

extension UInt8: BytecodeElement {}
extension UInt32: BytecodeElement {}
extension UInt16: BytecodeElement {}

extension CGFloat: BytecodeElement {
  internal static func readFrom(_ runner: BytecodeRunner) -> CGFloat {
    .init(Float32(bitPattern: runner.readInt()))
  }
}

extension CGPoint: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGPoint {
    .init(x: .readFrom(runner), y: .readFrom(runner))
  }
}

extension CGSize: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGSize {
    .init(width: .readFrom(runner), height: .readFrom(runner))
  }
}

extension CGRect: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGRect {
    .init(origin: .readFrom(runner), size: .readFrom(runner))
  }
}

extension Bool: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> Bool {
    UInt8.readFrom(runner) != 0
  }
}

extension CGPathFillRule: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGPathFillRule {
    CGPathFillRule(rawValue: Int(runner.read(UInt8.self)))!
  }
}

extension Array: BytecodeElement where Element: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> [Element] {
    let sz = BCSizeType.readFrom(runner)
    let arr: [Element] = (0..<sz).map { _ in .readFrom(runner) }
    return arr
  }
}

extension BCDashPattern: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCDashPattern {
    .init(.readFrom(runner), .readFrom(runner))
  }
}

extension CGPathDrawingMode: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGPathDrawingMode {
    CGPathDrawingMode(rawValue: Int32(UInt8.readFrom(runner)))!
  }
}

extension CGAffineTransform: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGAffineTransform {
    .init(
      a: .readFrom(runner),
      b: .readFrom(runner),
      c: .readFrom(runner),
      d: .readFrom(runner),
      tx: .readFrom(runner),
      ty: .readFrom(runner)
    )
  }
}

extension CGLineJoin: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGLineJoin {
    CGLineJoin(rawValue: Int32(UInt8.readFrom(runner)))!
  }
}

extension CGLineCap: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGLineCap {
    CGLineCap(rawValue: Int32(UInt8.readFrom(runner)))!
  }
}

extension BCRGBAColor: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCRGBAColor {
    BCRGBAColor(
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner)
    )
  }
}

extension CGGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGGradientDrawingOptions {
    CGGradientDrawingOptions(rawValue: UInt32(UInt8.readFrom(runner)))
  }
}

extension BCLinearGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner)
    -> BCLinearGradientDrawingOptions {
    .init(.readFrom(runner), .readFrom(runner), .readFrom(runner))
  }
}

extension BCRadialGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner)
    -> BCRadialGradientDrawingOptions {
    .init(
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner)
    )
  }
}

extension BCLocationAndColor: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCLocationAndColor {
    .init(.readFrom(runner), .readFrom(runner))
  }
}

extension BCShadow: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCShadow {
    .init(.readFrom(runner), .readFrom(runner), .readFrom(runner))
  }
}

extension CGBlendMode: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGBlendMode {
    CGBlendMode(rawValue: Int32(UInt8.readFrom(runner)))!
  }
}

extension CGColorRenderingIntent: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGColorRenderingIntent {
    CGColorRenderingIntent(rawValue: Int32(UInt8.readFrom(runner)))!
  }
}

extension Command: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> Command {
    Command(rawValue: .readFrom(runner))!
  }
}
