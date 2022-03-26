import CoreGraphics
import Foundation

public struct BCDashPattern {
  public var phase: CGFloat
  public var lengths: [CGFloat]

  @inlinable
  public init(phase: CGFloat, lengths: [CGFloat]) {
    self.phase = phase
    self.lengths = lengths
  }
}

public struct BCCubicCurve {
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

@usableFromInline
internal func unzipComponent(val: UInt8) -> CGFloat {
  CGFloat(val) / CGFloat(UInt8.max)
}

public struct BCRGBAColor {
  public var red: CGFloat
  public var green: CGFloat
  public var blue: CGFloat
  public var alpha: CGFloat

  @inlinable
  public init(
    r: UInt8,
    g: UInt8,
    b: UInt8,
    alpha: CGFloat
  ) {
    red = unzipComponent(val: r)
    green = unzipComponent(val: g)
    blue = unzipComponent(val: b)
    self.alpha = alpha
  }
}

public struct BCRGBColor {
  public var red: CGFloat
  public var green: CGFloat
  public var blue: CGFloat

  @inlinable
  public init(
    r: UInt8,
    g: UInt8,
    b: UInt8
  ) {
    red = unzipComponent(val: r)
    green = unzipComponent(val: g)
    blue = unzipComponent(val: b)
  }
}

public struct BCLinearGradientDrawingOptions {
  public var start: CGPoint
  public var end: CGPoint
  public var options: CGGradientDrawingOptions
  public var units: BCCoordinateUnits

  @inlinable
  public init(
    start: CGPoint,
    end: CGPoint,
    options: CGGradientDrawingOptions,
    units: BCCoordinateUnits
  ) {
    self.start = start
    self.end = end
    self.options = options
    self.units = units
  }
}

public struct BCRadialGradientDrawingOptions {
  public var startCenter: CGPoint
  public var startRadius: CGFloat
  public var endCenter: CGPoint
  public var endRadius: CGFloat
  public var drawingOptions: CGGradientDrawingOptions

  @inlinable
  public init(
    startCenter: CGPoint,
    startRadius: CGFloat,
    endCenter: CGPoint,
    endRadius: CGFloat,
    drawingOptions: CGGradientDrawingOptions
  ) {
    self.startCenter = startCenter
    self.startRadius = startRadius
    self.endCenter = endCenter
    self.endRadius = endRadius
    self.drawingOptions = drawingOptions
  }
}

public struct BCLocationAndColor {
  public var location: CGFloat
  public var color: BCRGBAColor

  @inlinable
  public init(location: CGFloat, color: BCRGBAColor) {
    self.location = location
    self.color = color
  }
}

public typealias BCGradient = [BCLocationAndColor]

public struct BCShadow {
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

public enum BCFillRule: Int {
  case winding, evenOdd
}

public typealias BCIdType = UInt32
public typealias BCSizeType = UInt32

public enum BCCoordinateUnits: UInt8 {
  case objectBoundingBox
  case userSpaceOnUse
}
