import CoreGraphics
import Foundation

public struct BCDashPattern {
  public let phase: CGFloat
  public let lengths: [CGFloat]
  public init(phase: CGFloat, lengths: [CGFloat]) {
    self.phase = phase
    self.lengths = lengths
  }
}

public struct BCCubicCurve {
  public let control1: CGPoint
  public let control2: CGPoint
  public let to: CGPoint
  public init(control1: CGPoint, control2: CGPoint, to: CGPoint) {
    self.control1 = control1
    self.control2 = control2
    self.to = to
  }
}

private func unzipComponent(val: UInt8) -> CGFloat {
  CGFloat(val) / CGFloat(UInt8.max)
}

public struct BCRGBAColor {
  public let red: CGFloat
  public let green: CGFloat
  public let blue: CGFloat
  public let alpha: CGFloat
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

public struct BCLinearGradientDrawingOptions {
  public let start: CGPoint
  public let end: CGPoint
  public let options: CGGradientDrawingOptions
  public init(
    start: CGPoint,
    end: CGPoint,
    drawingOptions: CGGradientDrawingOptions
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
  public let location: CGFloat
  public let color: BCRGBAColor
  public init(location: CGFloat, color: BCRGBAColor) {
    self.location = location
    self.color = color
  }
}

public typealias BCGradient = [BCLocationAndColor]

public struct BCShadow {
  public let offset: CGSize
  public let blur: CGFloat
  public let color: BCRGBAColor
  public init(offset: CGSize, blur: CGFloat, color: BCRGBAColor) {
    self.offset = offset
    self.blur = blur
    self.color = color
  }
}

public typealias BCIdType = UInt32
public typealias BCSizeType = UInt32
