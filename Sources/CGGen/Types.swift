import Base
@preconcurrency import CoreGraphics
import Foundation

public typealias RGBACGColor = RGBAColor<CGFloat>
public typealias RGBCGColor = RGBColor<CGFloat>

public struct Gradient: Sendable {
  public var locationAndColors: [(CGFloat, RGBACGColor)]

  public init(locationAndColors: [(CGFloat, RGBACGColor)]) {
    self.locationAndColors = locationAndColors
  }
}

public struct Shadow: Sendable {
  public var offset: CGSize
  public var blur: CGFloat
  public var color: RGBACGColor

  public init(offset: CGSize, blur: CGFloat, color: RGBACGColor) {
    self.offset = offset
    self.blur = blur
    self.color = color
  }
}

public struct DashPattern: Sendable {
  public let phase: CGFloat
  public let lengths: [CGFloat]

  public init(phase: CGFloat, lengths: [CGFloat]) {
    self.phase = phase
    self.lengths = lengths
  }
}
