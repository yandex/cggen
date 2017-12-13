// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public protocol LinearInterpolatable {
  associatedtype AbscissaType
  var abscissa: AbscissaType { get }
  func near(_ other: Self) -> Bool
  static func linearInterpolate(from lhs: Self, to rhs: Self, at x: AbscissaType) -> Self
}

extension Array where Element: LinearInterpolatable {
  public func removeIntermediates() -> [Element] {
    if count == 2 {
      return self
    }

    var result = [self[0]]
    var startIndex = 0
    for currentIndex in 1..<count - 1 {
      let ip = Element.linearInterpolate(from: self[startIndex], to: self[currentIndex + 1], at: self[currentIndex].abscissa)
      if !ip.near(self[currentIndex]) {
        result.append(self[currentIndex])
        startIndex = currentIndex
      }
    }
    result.append(last!)
    return result
  }
}

extension Sequence where Element: FloatingPoint {
  public func rootMeanSquare() -> Element {
    let valuesSquared = map { $0 * $0 }
    let meanSquare = valuesSquared.reduce(0, +) / Element(valuesSquared.count)
    return meanSquare.squareRoot()
  }
}
