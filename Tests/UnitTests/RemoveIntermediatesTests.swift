@testable import Base
import Foundation
import Testing

struct Point: Equatable, LinearInterpolatable {
  let x: Double
  let y: Double

  typealias AbscissaType = Double
  typealias DistanceType = Double

  public var abscissa: AbscissaType {
    x
  }

  func distanceTo(_ other: Point) -> DistanceType {
    let dx = x - other.x
    let dy = y - other.y
    return sqrt((dx * dx) + (dy * dy))
  }

  static func linearInterpolate(
    from lhs: Point,
    to rhs: Point,
    at x: Double
  ) -> Point {
    let dx = rhs.x - lhs.x
    let dy = rhs.y - lhs.y
    let k = dy / dx
    let b = lhs.y - k * lhs.x
    return Point(x: x, y: k * x + b)
  }
}

private let delta = Double.ulpOfOne * 100
private func line(k: Double, b: Double) -> (Double) -> Point {
  { Point(x: $0, y: k * $0 + b) }
}

@Suite struct RemoveIntermediatesTests {
  @Test func empty() {
    let points = [Point]()
    #expect(points.removeIntermediates(tolerance: 0) == points)
  }

  @Test func onePoint() {
    let points = [Point(x: 0, y: 0)]
    #expect(points.removeIntermediates(tolerance: 0) == points)
  }

  @Test func twoPoints() {
    let points = [Point(x: 0, y: 0), Point(x: 1, y: 3)]
    #expect(points.removeIntermediates(tolerance: 0) == points)
  }

  @Test func oneDirectlyProportionalLine() {
    let l = line(k: 1, b: 0)
    let points = stride(from: 0.0, to: 2.0, by: 0.01).map(l)
    #expect(
      points.removeIntermediates(tolerance: Double.ulpOfOne) ==
        [points.first!, points.last!]
    )
  }

  @Test func oneLine() {
    let l = line(k: -2, b: 10)
    let points = stride(from: -10.0, through: 2.0, by: 0.01).map(l)
    #expect(
      points.removeIntermediates(tolerance: delta) ==
        [points.first!, points.last!]
    )
  }

  @Test func twoLines() {
    let line1 = line(k: -1, b: 4)
    let line2 = line(k: 0.5, b: 4)
    let points1 = stride(from: -2, to: 0, by: 0.01).map(line1)
    let points2 = stride(from: 0, to: 2, by: 0.01).map(line2)
    let points = points1 + points2
    let expected = [points1.first!, points2.first!, points2.last!]
    #expect(
      points.removeIntermediates(tolerance: delta) ==
        expected
    )
  }

  @Test func twoLinesWithBigTolerance() {
    let line1 = line(k: -1, b: 0)
    let line2 = line(k: 1, b: 0)
    let points1 = stride(from: -1, to: 0, by: 0.01).map(line1)
    let points2 = stride(from: 0, to: 1, by: 0.01).map(line2)
    let points = points1 + points2
    let expected = [points1.first!, points2.first!, points2.last!]
    #expect(
      points.removeIntermediates(tolerance: 0.1) ==
        expected
    )
  }
}
