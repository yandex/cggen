@preconcurrency import Parsing

enum SVGShapeParser {
  typealias Attribute = SVGAttributeParser
  typealias AttributeGroup = SVGAttributeGroupParser

  struct ShapeParser<DataParser: Parser & Sendable>: Parser, Sendable
    where DataParser.Input == [String: String],
    DataParser.Output: Equatable & Sendable {
    typealias Input = [String: String]
    typealias Output = SVG.ShapeElement<DataParser.Output>

    let dataParser: DataParser

    init(_ dataParser: DataParser) {
      self.dataParser = dataParser
    }

    var body: some Parser<Input, Output> {
      Parse(SVG.ShapeElement.init) {
        AttributeGroup.core
        AttributeGroup.presentation
        Attribute.Transform(.transform)
        dataParser
      }
    }
  }

  static let rect = ShapeParser(
    Parse(SVG.RectData.init) {
      AttributeGroup.x
      AttributeGroup.y
      Attribute.Len(.rx)
      Attribute.Len(.ry)
      AttributeGroup.width
      AttributeGroup.height
    }
  )

  static let polygon = ShapeParser(
    Attribute.ListOfPoints(.points).map(SVG.PolygonData.init)
  )

  static let circle = ShapeParser(
    Parse(SVG.CircleData.init) {
      Attribute.Coord(.cx)
      Attribute.Coord(.cy)
      Attribute.Coord(.r)
    }
  )

  static let ellipse = ShapeParser(
    Parse(SVG.EllipseData.init) {
      Attribute.Coord(.cx)
      Attribute.Coord(.cy)
      Attribute.Len(.rx)
      Attribute.Len(.ry)
    }
  )

  static let path = ShapeParser(
    Parse(SVG.PathData.init) {
      Attribute.PathData(.d)
      Attribute.Num(.pathLength)
    }
  )
}
