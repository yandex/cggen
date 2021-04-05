import Foundation

import Foundation
import CoreGraphics
import BCCommon

protocol BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> Self
}

internal extension  BytecodeElement where Self: FixedWidthInteger {
  static func readFrom(_ runner: BytecodeRunner) -> Self {
    runner.readBytes()
  }
}

extension UInt8 : BytecodeElement {}
extension UInt32 : BytecodeElement {}
extension UInt16 : BytecodeElement {}

extension CGFloat: BytecodeElement {
  internal static func readFrom(_ runner: BytecodeRunner) -> CGFloat {
    .init(Float(bitPattern: runner.readBytes()))
  }
}

extension CGPoint: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGPoint {
    .init(x: runner.read(), y: runner.read())
  }
}

extension CGSize: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGSize {
    .init(width: runner.read(), height: runner.read())
  }
}

extension CGRect: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGRect {
    .init(origin: runner.read(), size: runner.read())
  }
}

extension Bool: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> Bool {
    runner.read(UInt8.self) != 0
  }
}

extension CGPathFillRule: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGPathFillRule {
    CGPathFillRule.init(rawValue: Int(runner.read(UInt8.self)))!
  }
}

extension Array: BytecodeElement where Element: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> Array<Element> {
    let sz = Int(runner.read(UInt32.self))
    var arr:[Element] = []
    arr.reserveCapacity(sz)
    for _ in 0..<sz {
      arr.append(runner.read())
    }
    return arr
  }
}

extension BCDashPattern: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCDashPattern {
    .init(phase: runner.read(), lengths: runner.read())
  }
}

extension CGPathDrawingMode: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGPathDrawingMode {
    CGPathDrawingMode.init(rawValue: Int32(runner.read(UInt8.self)))!
  }
}

extension CGAffineTransform: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGAffineTransform {
    .init(
      a: runner.read(),
      b: runner.read(),
      c: runner.read(),
      d: runner.read(),
      tx: runner.read(),
      ty: runner.read()
    )
  }
}

extension CGLineJoin: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGLineJoin {
    CGLineJoin.init(rawValue: Int32(runner.read(UInt8.self)))!
  }
}

extension CGLineCap: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGLineCap {
    CGLineCap.init(rawValue: Int32(runner.read(UInt8.self)))!
  }
}

extension BCRGBAColor: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCRGBAColor {
    BCRGBAColor(
      runner.read(),
      runner.read(),
      runner.read(),
      runner.read()
    )
  }
}

extension CGGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGGradientDrawingOptions {
    CGGradientDrawingOptions.init(rawValue: UInt32(runner.read(UInt8.self)))
  }
}

extension BCLinearGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCLinearGradientDrawingOptions {
    .init(runner.read(), runner.read(), runner.read())
  }
}

extension BCRadialGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCRadialGradientDrawingOptions {
    .init(runner.read(), runner.read(), runner.read(), runner.read(), runner.read())
  }
}

extension BCLocationAndColor: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCLocationAndColor {
    .init(runner.read(), runner.read())
  }
}

extension BCShadow: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> BCShadow {
    .init(runner.read(), runner.read(), runner.read())
  }
}

extension CGBlendMode: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGBlendMode {
    CGBlendMode.init(rawValue: Int32(runner.read(UInt8.self)))!
  }
}

extension CGColorRenderingIntent: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) -> CGColorRenderingIntent {
    CGColorRenderingIntent.init(rawValue: Int32(runner.read(UInt8.self)))!
  }
}
