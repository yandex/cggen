// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public struct RGBColor: Equatable {
  public let red: CGFloat
  public let green: CGFloat
  public let blue: CGFloat
  public init(red: CGFloat, green: CGFloat, blue: CGFloat) {
    self.red = red
    self.green = green
    self.blue = blue
  }

  public static let black = RGBColor(red: 0, green: 0, blue: 0)
}

public struct RGBAColor {
  public let red: CGFloat
  public let green: CGFloat
  public let blue: CGFloat
  public let alpha: CGFloat
  public var cgColor: CGColor {
    return CGColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  public static func rgb(_ rgb: RGBColor, alpha: CGFloat) -> RGBAColor {
    return RGBAColor(
      red: rgb.red, green: rgb.green,
      blue: rgb.blue, alpha: alpha
    )
  }
}
