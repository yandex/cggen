// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public protocol LinearInterpolatable {
  associatedtype AbscissaType
  associatedtype DistanceType: Comparable
  var abscissa: AbscissaType { get }
  func distanceTo(_ other: Self) -> DistanceType
  static func linearInterpolate(
    from lhs: Self,
    to rhs: Self,
    at x: AbscissaType
  ) -> Self
}

extension Array where Element: LinearInterpolatable {
  public func removeIntermediates(tolerance: Element.DistanceType) -> [Element] {
    typealias IndexAndError = (at: Int, error: Element.DistanceType)
    func maxLinearInterpolationError(in range: CountableClosedRange<Int>) -> IndexAndError {
      let start = self[range.lowerBound]
      let end = self[range.upperBound]
      let linearInterpolationErrorFor: (Element) -> Element.DistanceType = {
        Element.linearInterpolate(from: start, to: end, at: $0.abscissa).distanceTo($0)
      }
      let initialValue = (range.lowerBound, start.distanceTo(start))
      return zip(range, self[range])
        .reduce(initialValue) { intermediate, current in
          let maxEror = intermediate.1
          let error = linearInterpolationErrorFor(current.1)
          return error > maxEror ? (current.0, error) : intermediate
        }
    }

    func removeIntermediates(range: CountableClosedRange<Int>) -> ArraySlice<Element> {
      guard range.count >= 2 else {
        return self[range]
      }
      let (idxOfMaxError, maxError) = maxLinearInterpolationError(in: range)
      // Check whether linear interpolation has acceptable accuracy on this segment.
      // If not, split this segment into two, for each of which we recursively check
      // if linear interpolation is OK.
      if maxError > tolerance {
        let r1 = range.lowerBound...idxOfMaxError
        let r2 = idxOfMaxError...range.upperBound
        return removeIntermediates(range: r1) +
          removeIntermediates(range: r2).dropFirst()
      } else {
        return [self[range.lowerBound], self[range.upperBound]]
      }
    }
    return isEmpty ? [] : Array(removeIntermediates(range: CountableClosedRange(indices)))
  }
}

extension Sequence where Element: FloatingPoint {
  public func rootMeanSquare() -> Element {
    let (count, sumOfSquares) = reduce((0, 0)) { ($0.0 + 1, $0.1 + $1 * $1) }
    return (sumOfSquares / Element(count)).squareRoot()
  }
}
