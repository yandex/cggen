import CoreGraphics
import Foundation

public struct BCDashPattern {
  public let phase: CGFloat
  public let lengths: [CGFloat]
  public init(_ phase: CGFloat, _ lengths: [CGFloat]) {
    self.phase = phase
    self.lengths = lengths
  }
}

public struct BCRGBAColor {
  public let red: CGFloat
  public let green: CGFloat
  public let blue: CGFloat
  public let alpha: CGFloat
  public init(
    _ red: CGFloat,
    _ green: CGFloat,
    _ blue: CGFloat,
    _ alpha: CGFloat
  ) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }
}

public struct BCLinearGradientDrawingOptions {
  public let start: CGPoint
  public let end: CGPoint
  public let options: CGGradientDrawingOptions
  public init(
    _ start: CGPoint,
    _ end: CGPoint,
    _ drawingOptions: CGGradientDrawingOptions
  ) {
    self.start = start
    self.end = end
    options = drawingOptions
  }
}

public struct BCRadialGradientDrawingOptions {
  public let startCenter: CGPoint
  public let startRadius: CGFloat
  public let endCenter: CGPoint
  public let endRadius: CGFloat
  public let drawingOptions: CGGradientDrawingOptions
  public init(
    _ startCenter: CGPoint,
    _ startRadius: CGFloat,
    _ endCenter: CGPoint,
    _ endRadius: CGFloat,
    _ drawingOptions: CGGradientDrawingOptions
  ) {
    self.startCenter = startCenter
    self.startRadius = startRadius
    self.endCenter = endCenter
    self.endRadius = endRadius
    self.drawingOptions = drawingOptions
  }
}

public struct BCLocationAndColor {
  public let location: CGFloat
  public let color: BCRGBAColor
  public init(_ location: CGFloat, _ color: BCRGBAColor) {
    self.location = location
    self.color = color
  }
}

public typealias BCGradient = [BCLocationAndColor]

public struct BCShadow {
  public let offset: CGSize
  public let blur: CGFloat
  public let color: BCRGBAColor
  public init(_ offset: CGSize, _ blur: CGFloat, _ color: BCRGBAColor) {
    self.offset = offset
    self.blur = blur
    self.color = color
  }
}

public typealias BCIdType = UInt32
public typealias BCSizeType = UInt32
