@preconcurrency import Parsing

enum SVGShapeParser {
  typealias Value = SVGValueParser

  static let rect = AttributeSchema<SVG.Rect> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.x, \.data.x, Value.length)
    $0.field(.y, \.data.y, Value.length)
    $0.field(.rx, \.data.rx, Value.length)
    $0.field(.ry, \.data.ry, Value.length)
    $0.field(.width, \.data.width, Value.length)
    $0.field(.height, \.data.height, Value.length)
  }

  static let polygon = AttributeSchema<SVG.Polygon> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.points, \.data.points, Value.listOfPoints)
  }

  static let circle = AttributeSchema<SVG.Circle> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.cx, \.data.cx, Value.length)
    $0.field(.cy, \.data.cy, Value.length)
    $0.field(.r, \.data.r, Value.length)
  }

  static let ellipse = AttributeSchema<SVG.Ellipse> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.cx, \.data.cx, Value.length)
    $0.field(.cy, \.data.cy, Value.length)
    $0.field(.rx, \.data.rx, Value.length)
    $0.field(.ry, \.data.ry, Value.length)
  }

  static let path = AttributeSchema<SVG.Path> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.d, \.data.d, Value.pathData)
    $0.field(.pathLength, \.data.pathLength, Value.number)
  }
}
