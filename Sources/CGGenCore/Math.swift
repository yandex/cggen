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
  public func removeIntermediates(
    tolerance: Element.DistanceType
  ) -> [Element] {
    typealias IndexAndError = (at: Int, error: Element.DistanceType)
    func maxLinearInterpolationError(
      in range: CountableClosedRange<Int>
    ) -> IndexAndError {
      let start = self[range.lowerBound]
      let end = self[range.upperBound]
      let linearInterpolationErrorFor: (Element) -> Element.DistanceType = {
        Element.linearInterpolate(from: start, to: end, at: $0.abscissa)
          .distanceTo($0)
      }
      let initialValue = (range.lowerBound, start.distanceTo(start))
      // Only check intermediate points, not endpoints
      let intermediateRange = (range.lowerBound + 1)..<range.upperBound
      guard !intermediateRange.isEmpty else {
        return initialValue
      }
      return zip(intermediateRange, self[intermediateRange])
        .reduce(initialValue) { intermediate, current in
          let maxEror = intermediate.1
          let error = linearInterpolationErrorFor(current.1)
          return error > maxEror ? (current.0, error) : intermediate
        }
    }

    func removeIntermediates(
      range: CountableClosedRange<Int>
    ) -> ArraySlice<Element> {
      guard range.count >= 2 else {
        return self[range]
      }

      // Use iterative approach with explicit stack to avoid stack overflow
      var keep = [Bool](repeating: false, count: count)
      keep[range.lowerBound] = true
      keep[range.upperBound] = true

      var stack = [range]

      while let currentRange = stack.popLast() {
        // Skip ranges with less than 3 points (no intermediate points to check)
        guard currentRange.count > 2 else { continue }

        let (
          idxOfMaxError,
          maxError
        ) = maxLinearInterpolationError(in: currentRange)

        if maxError > tolerance {
          keep[idxOfMaxError] = true

          let r1 = currentRange.lowerBound...idxOfMaxError
          let r2 = idxOfMaxError...currentRange.upperBound

          // Only add ranges that have intermediate points to check
          if r1.count > 2 {
            stack.append(r1)
          }
          if r2.count > 2 {
            stack.append(r2)
          }
        }
      }

      // Build result from kept points within the range
      var result = [Element]()
      for i in range where keep[i] {
        result.append(self[i])
      }
      return ArraySlice(result)
    }
    return isEmpty ? [] :
      Array(removeIntermediates(range: CountableClosedRange(indices)))
  }
}

extension Sequence where Element: FloatingPoint {
  @inlinable
  public func rootMeanSquare() -> Element {
    // difficult typecheck avoidance
    typealias Acc = (count: Int, sum: Element)
    let (count, sum): Acc = reduce((0, 0) as Acc) { (acc: Acc, next: Element) in
      (acc.count + 1, acc.sum + next * next)
    }
    return (sum / Element(count)).squareRoot()
  }
}

public enum Matrix {
  public struct Column5<T: Equatable & Sendable>: Equatable, Sendable {
    public var c1: T
    public var c2: T
    public var c3: T
    public var c4: T
    public var c5: T

    @inlinable
    public init(c1: T, c2: T, c3: T, c4: T, c5: T) {
      self.c1 = c1
      self.c2 = c2
      self.c3 = c3
      self.c4 = c4
      self.c5 = c5
    }

    @inlinable
    public var components: [T] { [c1, c2, c3, c4, c5] }
  }

  public struct Row4<T: Equatable & Sendable>: Equatable, Sendable {
    public var r1: T
    public var r2: T
    public var r3: T
    public var r4: T

    @inlinable
    public init(r1: T, r2: T, r3: T, r4: T) {
      self.r1 = r1
      self.r2 = r2
      self.r3 = r3
      self.r4 = r4
    }

    @inlinable
    public var components: [T] { [r1, r2, r3, r4] }
  }

  public typealias D4x5<T: Equatable> = Row4<Column5<T>>

  @inlinable
  public static func diagonal4x5<T: Equatable & Sendable>(
    r1c1: T, r2c2: T, r3c3: T, r4c4: T, zero: T
  ) -> D4x5<T> {
    .init(
      r1: .init(c1: r1c1, c2: zero, c3: zero, c4: zero, c5: zero),
      r2: .init(c1: zero, c2: r2c2, c3: zero, c4: zero, c5: zero),
      r3: .init(c1: zero, c2: zero, c3: r3c3, c4: zero, c5: zero),
      r4: .init(c1: zero, c2: zero, c3: zero, c4: r4c4, c5: zero)
    )
  }

  @inlinable
  public static func scalar4x5<T: Equatable & Sendable>(
    λ: T, zero: T
  ) -> D4x5<T> {
    diagonal4x5(r1c1: λ, r2c2: λ, r3c3: λ, r4c4: λ, zero: zero)
  }
}

extension Comparable {
  @inlinable
  public func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }
}

extension BinaryFloatingPoint {
  // https://github.com/apple/swift-evolution/blob/master/proposals/0259-approximately-equal.md
  @inlinable
  public func isAlmostEqual(
    _ other: Self,
    maxRelDev: Self = 0.001
  ) -> Bool {
    precondition(maxRelDev >= Self.zero)
    precondition(isFinite && other.isFinite)
    guard self != other else { return true }
    guard !isZero else { return other.isAlmostZero() }
    guard !other.isZero else { return isAlmostZero() }
    let scale = max(abs(self), abs(other), .leastNormalMagnitude)
    return abs(self - other) < scale * maxRelDev
  }

  @inlinable
  public func isAlmostZero(
    absoluteTolerance tolerance: Self = Self.ulpOfOne.squareRoot()
  ) -> Bool {
    assert(tolerance > 0)
    return abs(self) < tolerance
  }
}

@inlinable
public func findCathetus<T: BinaryFloatingPoint>(
  otherCathetus: T,
  hypotenuse: T
) -> T {
  precondition(hypotenuse >= otherCathetus)
  return sqrt(hypotenuse * hypotenuse - otherCathetus * otherCathetus)
}

public protocol Point2D {
  associatedtype Coordinate
  var x: Coordinate { get set }
  var y: Coordinate { get set }
  init(x: Coordinate, y: Coordinate)
}

public protocol Vector2D {
  associatedtype Coordinate
  var dx: Coordinate { get set }
  var dy: Coordinate { get set }
  init(dx: Coordinate, dy: Coordinate)
}

extension Vector2D where Coordinate: BinaryFloatingPoint {
  @inlinable
  public init<PointType: Point2D>(
    from: PointType, to: PointType
  ) where PointType.Coordinate == Coordinate {
    self.init(dx: to.x - from.x, dy: to.y - from.y)
  }

  @inlinable
  public var length: Coordinate {
    sqrt(dx * dx + dy * dy)
  }

  @inlinable
  public static func *(lhs: Coordinate, rhs: Self) -> Self {
    .init(dx: lhs * rhs.dx, dy: lhs * rhs.dy)
  }

  @inlinable
  public func normalized() -> Self {
    let len = length
    precondition(len > 0)
    return .init(dx: dx / len, dy: dy / len)
  }

  @inlinable
  public func terminal<Point: Point2D>(
    pointType _: Point.Type = Point.self
  ) -> Point where Point.Coordinate == Coordinate {
    .init(x: dx, y: dy)
  }
}
