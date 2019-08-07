// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public struct Zero: Numeric, Comparable {
  @inlinable public var magnitude: Zero { return Zero() }

  @inlinable public init<T>(exactly _: T) where T: BinaryInteger {}
  @inlinable public init() {}
  @inlinable public init(integerLiteral _: Int) {}

  public static let zero = Zero()
  public static func -=(_: inout Zero, _: Zero) {}
  public static func +=(_: inout Zero, _: Zero) {}
  public static func *=(_: inout Zero, _: Zero) {}
  public static func *(_: Zero, _: Zero) -> Zero { return .init() }
  public static func +(_: Zero, _: Zero) -> Zero { return .init() }
  public static func -(_: Zero, _: Zero) -> Zero { return .init() }
  public static func <(_: Zero, _: Zero) -> Bool { return false }
}

public struct RGBAColorType<ColorT: Numeric, AlphaT: Numeric>: Equatable {
  public var red: ColorT
  public var green: ColorT
  public var blue: ColorT
  public var alpha: AlphaT

  @inlinable
  public init(red: ColorT, green: ColorT, blue: ColorT, alpha: AlphaT) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  @inlinable
  public init(gray: ColorT, alpha: AlphaT) {
    self.init(red: gray, green: gray, blue: gray, alpha: alpha)
  }

  @inlinable
  public func map<C: Numeric, A: Numeric>(
    colorT: (ColorT) -> C,
    alphaT: (AlphaT) -> A
  ) -> RGBAColorType<C, A> {
    return .init(
      red: colorT(red),
      green: colorT(green),
      blue: colorT(blue),
      alpha: alphaT(alpha)
    )
  }
}

public typealias RGBColor<T: Numeric> = RGBAColorType<T, Zero>
public typealias RGBAColor<T: Numeric> = RGBAColorType<T, T>

extension RGBAColorType where AlphaT == Zero {
  @inlinable
  public init(red: ColorT, green: ColorT, blue: ColorT) {
    self.init(red: red, green: green, blue: blue, alpha: Zero())
  }

  @inlinable
  public static func gray(_ gray: ColorT) -> RGBColor<ColorT> {
    return .init(red: gray, green: gray, blue: gray)
  }

  @inlinable
  public static func black() -> RGBColor<ColorT> {
    return .gray(ColorT.zero)
  }

  @inlinable
  public func map<U: Numeric>(_ transform: (ColorT) -> U) -> RGBColor<U> {
    return map(colorT: transform, alphaT: identity)
  }

  @inlinable
  public func with(alpha: ColorT) -> RGBAColor<ColorT> {
    return .init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension RGBAColorType where ColorT == AlphaT {
  @inlinable
  public func map<U: Numeric>(_ transform: (ColorT) -> U) -> RGBAColor<U> {
    return map(colorT: transform, alphaT: transform)
  }

  @inlinable
  public var components: [ColorT] {
    return [red, green, blue, alpha]
  }
}

extension RGBAColorType where ColorT: FixedWidthInteger, AlphaT == Zero {
  @inlinable
  public func norm<F: BinaryFloatingPoint>(
    _: F.Type = F.self
  ) -> RGBColor<F> {
    return map { F($0) / F(ColorT.max) }
  }
}

extension RGBAColorType where ColorT: FixedWidthInteger, AlphaT == ColorT {
  @inlinable
  public func norm<F: BinaryFloatingPoint>(
    _: F.Type = F.self
  ) -> RGBAColor<F> {
    return map { F($0) / F(ColorT.max) }
  }
}
