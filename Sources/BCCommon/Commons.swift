import CoreGraphics
import Foundation

public struct BCDashPattern: Sendable {
  public var phase: CGFloat
  public var lengths: [CGFloat]

  @inlinable
  public init(phase: CGFloat, lengths: [CGFloat]) {
    self.phase = phase
    self.lengths = lengths
  }
}

public struct BCCubicCurve: Sendable {
  public var control1: CGPoint
  public var control2: CGPoint
  public var to: CGPoint

  @inlinable
  public init(control1: CGPoint, control2: CGPoint, to: CGPoint) {
    self.control1 = control1
    self.control2 = control2
    self.to = to
  }
}

public struct BCQuadCurve: Sendable {
  public var control: CGPoint
  public var to: CGPoint

  @inlinable
  public init(control: CGPoint, to: CGPoint) {
    self.control = control
    self.to = to
  }
}

@usableFromInline
func unzipComponent(val: UInt8) -> CGFloat {
  CGFloat(val) / CGFloat(UInt8.max)
}

public struct BCRGBAColor: Sendable {
  public var red: UInt8
  public var green: UInt8
  public var blue: UInt8
  public var alpha: CGFloat

  @inlinable
  public init(
    r: UInt8,
    g: UInt8,
    b: UInt8,
    alpha: CGFloat
  ) {
    red = r
    green = g
    blue = b
    self.alpha = alpha
  }
}

public struct BCRGBColor: Sendable {
  public var red: UInt8
  public var green: UInt8
  public var blue: UInt8

  @inlinable
  public init(
    r: UInt8,
    g: UInt8,
    b: UInt8
  ) {
    red = r
    green = g
    blue = b
  }
}

public struct BCLinearGradientDrawingOptions: Sendable {
  public var start: CGPoint
  public var end: CGPoint
  public var options: CGGradientDrawingOptions
  public var units: BCCoordinateUnits
  public var transform: CGAffineTransform?

  @inlinable
  public init(
    start: CGPoint,
    end: CGPoint,
    options: CGGradientDrawingOptions,
    units: BCCoordinateUnits,
    transform: CGAffineTransform?
  ) {
    self.start = start
    self.end = end
    self.options = options
    self.units = units
    self.transform = transform
  }
}

public struct BCRadialGradientDrawingOptions: Sendable {
  public var startCenter: CGPoint
  public var startRadius: CGFloat
  public var endCenter: CGPoint
  public var endRadius: CGFloat
  public var drawingOptions: CGGradientDrawingOptions
  public var transform: CGAffineTransform?

  @inlinable
  public init(
    startCenter: CGPoint,
    startRadius: CGFloat,
    endCenter: CGPoint,
    endRadius: CGFloat,
    drawingOptions: CGGradientDrawingOptions,
    transform: CGAffineTransform?
  ) {
    self.startCenter = startCenter
    self.startRadius = startRadius
    self.endCenter = endCenter
    self.endRadius = endRadius
    self.drawingOptions = drawingOptions
    self.transform = transform
  }
}

public struct BCLocationAndColor: Sendable {
  public var location: CGFloat
  public var color: BCRGBAColor

  @inlinable
  public init(location: CGFloat, color: BCRGBAColor) {
    self.location = location
    self.color = color
  }
}

public typealias BCGradient = [BCLocationAndColor]

public struct BCShadow: Sendable {
  public var offset: CGSize
  public var blur: CGFloat
  public var color: BCRGBAColor

  @inlinable
  public init(offset: CGSize, blur: CGFloat, color: BCRGBAColor) {
    self.offset = offset
    self.blur = blur
    self.color = color
  }
}

public enum BCFillRule: UInt8, Sendable {
  case winding, evenOdd
}

public typealias BCIdType = UInt32
public typealias BCSizeType = UInt32

public enum BCCoordinateUnits: UInt8, Sendable {
  case objectBoundingBox
  case userSpaceOnUse
}
