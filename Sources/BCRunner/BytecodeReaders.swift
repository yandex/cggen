import CoreGraphics
import Foundation

import BCCommon

protocol BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> Self
}

struct EnumerationError<T>: Swift.Error {
}

extension BytecodeElement where Self: FixedWidthInteger {
  internal static func readFrom(_ runner: BytecodeRunner) throws -> Self {
    try runner.readInt()
  }
}

extension UInt8: BytecodeElement {}
extension UInt32: BytecodeElement {}
extension UInt16: BytecodeElement {}

extension BytecodeElement where Self: RawRepresentable, Self.RawValue: FixedWidthInteger {
  internal static func readFrom(_ runner: BytecodeRunner) throws -> Self {
    let rawValue: UInt8 = try runner.readInt()
    let converted = Self.RawValue(rawValue)
    guard let ret = Self(rawValue: converted) else {
      throw EnumerationError<Self>()
    }
    return ret
  }
}

extension CGBlendMode: BytecodeElement {}
extension CGPathFillRule: BytecodeElement {}
extension CGPathDrawingMode: BytecodeElement {}


extension CGFloat: BytecodeElement {
  internal static func readFrom(_ runner: BytecodeRunner) throws -> CGFloat {
    try .init(Float32(bitPattern: runner.readInt()))
  }
}

extension CGPoint: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> CGPoint {
    try .init(x: .readFrom(runner), y: .readFrom(runner))
  }
}

extension CGSize: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> CGSize {
    try .init(width: .readFrom(runner), height: .readFrom(runner))
  }
}

extension CGRect: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> CGRect {
    try .init(origin: .readFrom(runner), size: .readFrom(runner))
  }
}

extension Bool: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> Bool {
    try UInt8.readFrom(runner) != 0
  }
}

extension Array: BytecodeElement where Element: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> [Element] {
    let sz = try BCSizeType.readFrom(runner)
    let arr: [Element] = try (0..<sz).map { _ in try .readFrom(runner) }
    return arr
  }
}

extension BCDashPattern: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws  -> BCDashPattern {
    try .init(.readFrom(runner), .readFrom(runner))
  }
}

extension CGAffineTransform: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> CGAffineTransform {
    try .init(
      a: .readFrom(runner),
      b: .readFrom(runner),
      c: .readFrom(runner),
      d: .readFrom(runner),
      tx: .readFrom(runner),
      ty: .readFrom(runner)
    )
  }
}

extension CGLineJoin: BytecodeElement {}
extension CGLineCap: BytecodeElement {}

extension BCRGBAColor: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> BCRGBAColor {
    try BCRGBAColor(
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner)
    )
  }
}

extension CGGradientDrawingOptions: BytecodeElement {}

extension BCLinearGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws
    -> BCLinearGradientDrawingOptions {
    try .init(.readFrom(runner), .readFrom(runner), .readFrom(runner))
  }
}

extension BCRadialGradientDrawingOptions: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws
    -> BCRadialGradientDrawingOptions {
    try .init(
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner),
      .readFrom(runner)
    )
  }
}

extension BCLocationAndColor: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> BCLocationAndColor {
    try .init(.readFrom(runner), .readFrom(runner))
  }
}

extension BCShadow: BytecodeElement {
  static func readFrom(_ runner: BytecodeRunner) throws -> BCShadow {
    try .init(.readFrom(runner), .readFrom(runner), .readFrom(runner))
  }
}

extension CGColorRenderingIntent: BytecodeElement {}

extension Command: BytecodeElement {}
