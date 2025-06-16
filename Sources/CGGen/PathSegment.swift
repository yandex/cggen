@preconcurrency import CoreGraphics

public enum PathSegment: Sendable {
  case moveTo(CGPoint)
  case curveTo(CGPoint, CGPoint, CGPoint)
  case lineTo(CGPoint)
  case appendRectangle(CGRect)
  case appendRoundedRect(CGRect, rx: CGFloat, ry: CGFloat)
  case addEllipse(in: CGRect)
  case addArc(
    center: CGPoint,
    radius: CGFloat,
    startAngle: CGFloat,
    endAngle: CGFloat,
    clockwise: Bool
  )
  case closePath
  case endPath

  case lines([CGPoint])
  case composite([PathSegment])

  public static let empty: PathSegment = .composite([])
}
