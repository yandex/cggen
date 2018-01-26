// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public protocol LinearInterpolatable {
  associatedtype AbscissaType
  associatedtype DistanceType: Comparable
  var abscissa: AbscissaType { get }
  func distanceTo(_ other: Self) -> DistanceType
  static func linearInterpolate(from lhs: Self, to rhs: Self, at x: AbscissaType) -> Self
}

extension Array where Element: LinearInterpolatable {
  public func removeIntermediates(tolerance: Element.DistanceType) -> [Element] {
    func farthest(in range: CountableClosedRange<Int>) -> (Int, Element.DistanceType) {
      let start = self[range.lowerBound]
      let end = self[range.upperBound]
      let distanceFromLineTo: (Element) -> Element.DistanceType = {
        Element.linearInterpolate(from: start, to: end, at: $0.abscissa).distanceTo($0)
      }
      let zeroDist = start.distanceTo(start)
      return zip(CountableRange(range), self[range])
        .reduce((range.lowerBound, zeroDist)) { intermediate, current in
          let maxDistance = intermediate.1
          let distance = distanceFromLineTo(current.1)
          if distance > maxDistance {
            return (current.0, distance)
          } else {
            return intermediate
          }
        }
    }

    func removeIntermediates(range: CountableClosedRange<Int>) -> ArraySlice<Element> {
      guard range.count >= 2 else {
        return self[range]
      }
      let (farthestIdx, distanceToFarthest) = farthest(in: range)
      if distanceToFarthest > tolerance {
        let r1 = range.lowerBound...farthestIdx
        let r2 = farthestIdx...range.upperBound
        return removeIntermediates(range: r1) + removeIntermediates(range: r2).dropFirst()
      } else {
        return [self[range.lowerBound], self[range.upperBound]]
      }
    }
    return isEmpty ? [] : Array(removeIntermediates(range: 0...count - 1))
  }
}

extension Sequence where Element: FloatingPoint {
  public func rootMeanSquare() -> Element {
    let (count, sumOfSquares) = reduce((0, 0)) { ($0.0 + 1, $0.1 + $1 * $1) }
    return (sumOfSquares / Element(count)).squareRoot()
  }
}
