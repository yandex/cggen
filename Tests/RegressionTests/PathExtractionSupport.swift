import CoreGraphics
import Foundation
import Testing

import Base
import CGGenCLI
import CGGenIR
import CGGenRuntime
@_spi(Testing) import CGGenRTSupport

func testPathExtraction(
  path: CGPath,
  svg: URL
) throws {
  let bytecode = try getPathBytecode(from: svg)

  let pathAccumulator = CGMutablePath()
  try runPathBytecode(pathAccumulator, fromData: Data(bytecode))

  #expect(pathAccumulator.isAlmostEqual(to: path, tolerance: 0.0001))
}

extension CGPath {
  static func from(_ segments: [PathSegment]) -> CGMutablePath {
    let mutablePath = CGMutablePath()
    mutablePath.add(segments: segments)
    return mutablePath
  }
}

extension CGMutablePath {
  func add(segments: [PathSegment]) {
    segments.forEach(add(segment:))
  }

  private func add(segment: PathSegment) {
    switch segment {
    case let .moveTo(to):
      move(to: to)
    case let .curveTo(c1, c2, to):
      addCurve(to: to, control1: c1, control2: c2)
    case let .quadCurveTo(control, to):
      addQuadCurve(to: to, control: control)
    case let .lineTo(to):
      addLine(to: to)
    case let .appendRectangle(rect):
      addRect(rect)
    case let .appendRoundedRect(rect, rx, ry):
      addRoundedRect(in: rect, cornerWidth: rx, cornerHeight: ry)
    case let .addEllipse(rect):
      addEllipse(in: rect)
    case let .addArc(center, radius, startAngle, endAngle, clockwise):
      addArc(
        center: center,
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: clockwise
      )
    case .closePath:
      closeSubpath()
    case .endPath:
      assertionFailure("not implemented")
    case let .lines(arr):
      addLines(between: arr)
    case let .composite(arr):
      arr.forEach(add(segment:))
    }
  }
}

extension CGPathElement {
  fileprivate var pathSegment: PathSegment {
    switch type {
    case .moveToPoint:
      let to = points.pointee
      return .moveTo(to)
    case .addLineToPoint:
      let to = points.pointee
      return .lineTo(to)
    case .addQuadCurveToPoint:
      let control = points.pointee
      let to = points.advanced(by: 1).pointee
      return .quadCurveTo(control, to)
    case .addCurveToPoint:
      let control1 = points.pointee
      let control2 = points.advanced(by: 1).pointee
      let to = points.advanced(by: 2).pointee
      return .curveTo(control1, control2, to)
    case .closeSubpath:
      return .closePath
    @unknown default:
      assertionFailure("unknown cgpath element")
      return .empty
    }
  }
}

extension CGPath {
  func isAlmostEqual(to other: CGPath, tolerance: CGFloat) -> Bool {
    let pairs = zip(segments, other.segments)
    for (lhsElement, rhsElement) in pairs {
      guard lhsElement.isAlmostEqual(to: rhsElement, tolerance: tolerance)
      else { return false }
    }
    return true
  }

  private var segments: [PathSegment] {
    var output = [PathSegment]()
    applyWithBlock { p in
      let element = p.pointee
      output.append(element.pathSegment)
    }
    return output
  }
}

extension PathSegment {
  func isAlmostEqual(to other: PathSegment, tolerance: CGFloat) -> Bool {
    let lhs = self
    switch (lhs, other) {
    case let (.moveTo(a), .moveTo(b)):
      return a.isAlmostEqual(to: b, tolerance: tolerance)
    case let (.lineTo(a), .lineTo(b)):
      return a.isAlmostEqual(to: b, tolerance: tolerance)
    case let (.curveTo(a1, a2, a3), .curveTo(b1, b2, b3)):
      return a1.isAlmostEqual(to: b1, tolerance: tolerance) &&
        a2.isAlmostEqual(to: b2, tolerance: tolerance) &&
        a3.isAlmostEqual(to: b3, tolerance: tolerance)
    case let (.quadCurveTo(a1, a2), .quadCurveTo(b1, b2)):
      return a1.isAlmostEqual(to: b1, tolerance: tolerance) &&
        a2.isAlmostEqual(to: b2, tolerance: tolerance)
    case let (.addArc(a1, a2, a3, a4, a5), .addArc(b1, b2, b3, b4, b5)):
      return a1.isAlmostEqual(to: b1, tolerance: tolerance) &&
        a2.isAlmostEqual(to: b2, tolerance: tolerance) &&
        a3.isAlmostEqual(to: b3, tolerance: tolerance) &&
        a4.isAlmostEqual(to: b4, tolerance: tolerance) &&
        a5 == b5
    case let (.lines(arr1), .lines(arr2)):
      if arr1.count != arr2.count { return false }
      let pairs = zip(arr1, arr2)
      for (p1, p2) in pairs {
        if !p1.isAlmostEqual(to: p2, tolerance: tolerance) {
          return false
        }
      }
      return true
    case (.moveTo, _), (.curveTo, _), (.quadCurveTo, _), (.lineTo, _), (
      .appendRectangle,
      _
    ),
    (.appendRoundedRect, _), (.addEllipse, _), (.addArc, _),
    (.closePath, _), (.endPath, _),
    (.lines, _), (.composite, _):
      assertionFailure("unsupported pair of segments to compare")
      return false
    }
  }
}

extension CGPoint {
  func isAlmostEqual(to other: CGPoint, tolerance: CGFloat) -> Bool {
    x.isAlmostEqual(to: other.x, tolerance: tolerance) && y.isAlmostEqual(
      to: other.y,
      tolerance: tolerance
    )
  }
}

extension CGFloat {
  func isAlmostEqual(to other: CGFloat, tolerance: CGFloat) -> Bool {
    abs(self - other) <= tolerance
  }
}
