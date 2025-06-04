import CoreGraphics

import BCCommon

public struct InvalidRawValue<T: RawRepresentable>: Swift.Error
  where T.RawValue: Sendable {
  public typealias enumType = T
  public typealias rawType = T.RawValue
  public var rawValue: rawType
  public init(rawValue: rawType) {
    self.rawValue = rawValue
  }
}

// MARK: - Bytecode

struct Bytecode {
  enum ReadingError: Swift.Error {
    case outOfBounds(left: Int, required: Int)
    case isNotPOD(Any.Type)
  }

  var base: UnsafeRawPointer
  var count: Int

  init(base: UnsafeRawPointer, count: Int) {
    self.base = base
    self.count = count
  }

  mutating func read<T: FixedWidthInteger>(type _: T.Type) throws -> T {
    let size = MemoryLayout<T>.size

    guard _isPOD(T.self) else { throw ReadingError.isNotPOD(T.self) }
    guard size <= count else {
      throw ReadingError.outOfBounds(left: count, required: size)
    }

    var value: T = 0
    memcpy(&value, base, size)
    base = base.advanced(by: size)
    count -= size

    return T(littleEndian: value)
  }

  mutating func advance(count: Int) -> Self {
    defer {
      base = base.advanced(by: count)
      self.count -= count
    }
    return Self(base: base, count: count)
  }
}

protocol BytecodeDecodable {
  init(bytecode: inout Bytecode) throws
}

// MARK: Conforamnces

extension BytecodeDecodable
  where Self: RawRepresentable, RawValue: FixedWidthInteger & Sendable {
  init(bytecode: inout Bytecode) throws {
    let rawValue = try bytecode.read(type: UInt8.self)
    let converted = Self.RawValue(rawValue)
    guard let ret = Self(rawValue: converted) else {
      throw InvalidRawValue<Self>(rawValue: converted)
    }
    self = ret
  }
}

extension DrawCommand: BytecodeDecodable {}
extension PathCommand: BytecodeDecodable {}
extension BCFillRule: BytecodeDecodable {}
extension BCCoordinateUnits: BytecodeDecodable {}

extension BCDashPattern: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      phase: .init(bytecode: &bytecode), lengths: .init(bytecode: &bytecode)
    )
  }
}

extension BCRGBAColor: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      r: .init(bytecode: &bytecode),
      g: .init(bytecode: &bytecode),
      b: .init(bytecode: &bytecode),
      alpha: .init(bytecode: &bytecode)
    )
  }
}

extension BCRGBColor: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      r: .init(bytecode: &bytecode),
      g: .init(bytecode: &bytecode),
      b: .init(bytecode: &bytecode)
    )
  }
}

extension BCLinearGradientDrawingOptions: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      start: .init(bytecode: &bytecode),
      end: .init(bytecode: &bytecode),
      options: .init(bytecode: &bytecode),
      units: .init(bytecode: &bytecode),
      transform: .init(bytecode: &bytecode)
    )
  }
}

extension BCRadialGradientDrawingOptions: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      startCenter: .init(bytecode: &bytecode),
      startRadius: .init(bytecode: &bytecode),
      endCenter: .init(bytecode: &bytecode),
      endRadius: .init(bytecode: &bytecode),
      drawingOptions: .init(bytecode: &bytecode),
      transform: .init(bytecode: &bytecode)
    )
  }
}

extension BCLocationAndColor: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      location: .init(bytecode: &bytecode), color: .init(bytecode: &bytecode)
    )
  }
}

extension BCShadow: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      offset: .init(bytecode: &bytecode),
      blur: .init(bytecode: &bytecode),
      color: .init(bytecode: &bytecode)
    )
  }
}

extension BCCubicCurve: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      control1: .init(bytecode: &bytecode),
      control2: .init(bytecode: &bytecode),
      to: .init(bytecode: &bytecode)
    )
  }
}

// MARK: Legacy Conforamnces

// It's suspicious to conform types from SDK to custom protocols

extension BytecodeDecodable where Self: FixedWidthInteger {
  init(bytecode: inout Bytecode) throws {
    self = try bytecode.read(type: Self.self)
  }
}

extension UInt8: BytecodeDecodable {}
extension UInt32: BytecodeDecodable {}
extension UInt16: BytecodeDecodable {}

extension CGBlendMode: BytecodeDecodable {}
extension CGPathDrawingMode: BytecodeDecodable {}
extension CGLineJoin: BytecodeDecodable {}
extension CGLineCap: BytecodeDecodable {}
extension CGGradientDrawingOptions: BytecodeDecodable {}
extension CGColorRenderingIntent: BytecodeDecodable {}

extension CGFloat: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    let float32 = try Float32(bitPattern: bytecode.read(type: UInt32.self))
    self.init(float32)
  }
}

extension CGPoint: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(x: .init(bytecode: &bytecode), y: .init(bytecode: &bytecode))
  }
}

extension CGSize: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      width: .init(bytecode: &bytecode), height: .init(bytecode: &bytecode)
    )
  }
}

extension CGRect: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      origin: .init(bytecode: &bytecode), size: .init(bytecode: &bytecode)
    )
  }
}

extension Array: BytecodeDecodable where Element: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    let size = try bytecode.read(type: BCSizeType.self)
    try self.init((0..<size).map { _ in try .init(bytecode: &bytecode) })
  }
}

extension Optional where Wrapped: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    if try Bool(bytecode: &bytecode) {
      self = try .some(Wrapped(bytecode: &bytecode))
    } else {
      self = .none
    }
  }
}

extension CGAffineTransform: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(
      a: .init(bytecode: &bytecode),
      b: .init(bytecode: &bytecode),
      c: .init(bytecode: &bytecode),
      d: .init(bytecode: &bytecode),
      tx: .init(bytecode: &bytecode),
      ty: .init(bytecode: &bytecode)
    )
  }
}

extension Bool: BytecodeDecodable {
  init(bytecode: inout Bytecode) throws {
    try self.init(UInt8(bytecode: &bytecode) != 0)
  }
}
