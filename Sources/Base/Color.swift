import Foundation

public struct Ø: Numeric, Comparable {
  @inlinable public var magnitude: Ø { Ø() }

  @inlinable public init<T>(exactly _: T) where T: BinaryInteger {}
  @inlinable public init() {}
  @inlinable public init(integerLiteral _: Int) {}

  public static let zero = Ø()
  @inlinable public static func -=(_: inout Ø, _: Ø) {}
  @inlinable public static func +=(_: inout Ø, _: Ø) {}
  @inlinable public static func *=(_: inout Ø, _: Ø) {}
  @inlinable public static func *(_: Ø, _: Ø) -> Ø { .init() }
  @inlinable public static func +(_: Ø, _: Ø) -> Ø { .init() }
  @inlinable public static func -(_: Ø, _: Ø) -> Ø { .init() }
  @inlinable public static func <(_: Ø, _: Ø) -> Bool { false }
}

public struct RGBAColorType<Component: Numeric, Alpha: Numeric>: Equatable {
  public var red: Component
  public var green: Component
  public var blue: Component
  public var alpha: Alpha

  @inlinable
  public init(red: Component, green: Component, blue: Component, alpha: Alpha) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  @inlinable
  public init(gray: Component, alpha: Alpha) {
    self.init(red: gray, green: gray, blue: gray, alpha: alpha)
  }

  @inlinable
  public func map<C: Numeric, A: Numeric>(
    Component: (Component) -> C,
    alphaT: (Alpha) -> A
  ) -> RGBAColorType<C, A> {
    .init(
      red: Component(red),
      green: Component(green),
      blue: Component(blue),
      alpha: alphaT(alpha)
    )
  }
}

public typealias RGBColor<T: Numeric> = RGBAColorType<T, Ø>
public typealias RGBAColor<T: Numeric> = RGBAColorType<T, T>

extension RGBAColorType where Alpha == Ø {
  @inlinable
  public init(red: Component, green: Component, blue: Component) {
    self.init(red: red, green: green, blue: blue, alpha: Ø())
  }

  @inlinable
  public static func gray(_ gray: Component) -> RGBColor<Component> {
    .init(red: gray, green: gray, blue: gray)
  }

  @inlinable
  public static func black() -> RGBColor<Component> {
    .gray(Component.zero)
  }

  @inlinable
  public func map<U: Numeric>(_ transform: (Component) -> U) -> RGBColor<U> {
    map(Component: transform, alphaT: identity)
  }

  @inlinable
  public func withAlpha<Alpha>(
    _ alpha: Alpha
  ) -> RGBAColorType<Component, Alpha> {
    .init(red: red, green: green, blue: blue, alpha: alpha)
  }

  @inlinable
  public var components: [Component] {
    [red, green, blue]
  }
}

extension RGBAColorType where Alpha == Ø, Component: FixedWidthInteger {
  @inlinable
  public static func white() -> RGBColor<Component> {
    .gray(Component.max)
  }
}

extension RGBAColorType where Component == Alpha {
  @inlinable
  public func map<U: Numeric>(_ transform: (Component) -> U) -> RGBAColor<U> {
    map(Component: transform, alphaT: transform)
  }

  @inlinable
  public var components: [Component] {
    [red, green, blue, alpha]
  }
}

extension RGBAColorType where Component: FixedWidthInteger, Alpha == Ø {
  @inlinable
  public func norm<F: BinaryFloatingPoint>(
    _: F.Type = F.self
  ) -> RGBColor<F> {
    map { F($0) / F(Component.max) }
  }
}

extension RGBAColorType where Component: FixedWidthInteger, Alpha == Component {
  @inlinable
  public func norm<F: BinaryFloatingPoint>(
    _: F.Type = F.self
  ) -> RGBAColor<F> {
    map { F($0) / F(Component.max) }
  }
}
