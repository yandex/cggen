import Base
import Foundation
@preconcurrency import Parsing

// MARK: - Attribute Enum

enum Attribute: String {
  // XML
  case xmlns, xmlnsxlink = "xmlns:xlink"
  // Core
  case id

  case x, y, width, height, rx, ry

  // Filters
  case result, `in`, in2, mode

  // - Presentation
  case clipRule = "clip-rule", clipPath = "clip-path", mask, opacity
  case filter
  case stopColor = "stop-color", stopOpacity = "stop-opacity"
  case gradientTransform, gradientUnits
  // Color and Painting
  case colorInterpolation = "color-interpolation"
  case colorInterpolationFilters = "color-interpolation-filters"
  case colorProfile = "color-profile"
  case colorRendering = "color-rendering"
  case fill
  case fillOpacity = "fill-opacity", fillRule = "fill-rule"
  case imageRendering = "image-rendering"
  case marker
  case markerEnd = "marker-end", markerMid = "marker-mid"
  case markerStart = "marker-start"
  case shapeRendering = "shape-rendering"
  case stroke
  case strokeDasharray = "stroke-dasharray"
  case strokeDashoffset = "stroke-dashoffset"
  case strokeLinecap = "stroke-linecap", strokeLinejoin = "stroke-linejoin"
  case strokeMiterlimit = "stroke-miterlimit", strokeOpacity = "stroke-opacity"
  case strokeWidth = "stroke-width"
  case textRendering = "text-rendering"

  case viewBox, version
  case points
  case transform
  case offset
  case x1, y1, x2, y2
  case d, pathLength
  case cx, cy, r, fx, fy

  case xlinkHref = "xlink:href"
  case filterUnits
  case type, values, floodColor = "flood-color", floodOpacity = "flood-opacity"
  case stdDeviation
  case dx, dy

  case maskUnits, maskContentUnits, clipPathUnits

  // Ignore
  case maskType = "mask-type"
}

enum SVGAttributeParser {
  typealias AttributeParserProtocol<T> = Parser<[String: String], T?>
  struct Base<P: Parser>: Parser where P.Input == Substring {
    var attribute: Attribute
    var valueParser: P

    init(_ parser: P, _ attribute: Attribute) {
      self.attribute = attribute
      valueParser = parser
    }

    init(_ parser: (SVGValueParser.Type) -> P, _ attribute: Attribute) {
      self.attribute = attribute
      valueParser = parser(SVGValueParser.self)
    }

    var body: some Parser<[String: String], P.Output?> {
      Optionally {
        DicitionaryKey<String, String>(attribute.rawValue)
          .map { $0[...] }.pipe { valueParser }
      }
    }
  }

  // MARK: - Nested Attribute Parsers

  struct Len: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.Length> {
      Base(\.length, attribute)
    }
  }

  // Since SVG.Coordinate is just a typealias for SVG.Length,
  // Coord can be a typealias for Len
  typealias Coord = Len

  struct Color: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.Color> {
      Base(\.rgbcolor, attribute)
    }
  }

  struct Paint: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.Paint> {
      Base(\.paint, attribute)
    }
  }

  struct ViewBox: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.ViewBox> {
      Base(\.viewBox, attribute)
    }
  }

  struct Num: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.Float> {
      Base(\.number, attribute)
    }
  }

  struct NumList: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<[SVG.Float]> {
      Base(\.listOfNumbers, attribute)
    }
  }

  struct NumberOptionalNumber: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.NumberOptionalNumber> {
      Base(\.numberOptionalNumber, attribute)
    }
  }

  struct Identifier: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<String> {
      Base(\.identifier, attribute)
    }
  }

  struct Transform: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<[SVG.Transform]> {
      Base(\.transformsList, attribute)
    }
  }

  struct ListOfPoints: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.CoordinatePairs> {
      Base(\.listOfPoints, attribute)
    }
  }

  struct PathData: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<[SVG.PathData.Command]> {
      Base(\.pathData, attribute)
    }
  }

  struct StopOffset: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.Stop.Offset> {
      Base(\.stopOffset, attribute)
    }
  }

  struct FillRule: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.FillRule> {
      Base(SVG.FillRule.parser(), attribute)
    }
  }

  struct LineCap: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.LineCap> {
      Base(SVG.LineCap.parser(), attribute)
    }
  }

  struct LineJoin: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.LineJoin> {
      Base(SVG.LineJoin.parser(), attribute)
    }
  }

  struct Funciri: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<String> {
      Base(\.funciri, attribute)
    }
  }

  struct ColorInterpolation: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.ColorInterpolation> {
      Base(SVG.ColorInterpolation.parser(), attribute)
    }
  }

  struct IgnoreAttribute: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<Substring> {
      Base(Rest(), attribute)
    }
  }

  struct DashArray: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<[SVG.Length]> {
      Base(\.dashArray, attribute)
    }
  }

  struct Units: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.Units> {
      Base(SVG.Units.parser(), attribute)
    }
  }

  struct Iri: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<String> {
      Base(\.iri, attribute)
    }
  }

  struct FilterPrimitiveIn: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.FilterPrimitiveIn> {
      Base(\.filterPrimitiveIn, attribute)
    }
  }

  struct BlendMode: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.BlendMode> {
      Base(\.blendMode, attribute)
    }
  }

  struct FeColorMatrixType: Parser {
    var attribute: Attribute

    init(_ attribute: Attribute) {
      self.attribute = attribute
    }

    var body: some AttributeParserProtocol<SVG.FilterPrimitiveFeColorMatrix
      .Kind
    > {
      Base(
        SVG.FilterPrimitiveFeColorMatrix.Kind.parser(),
        attribute
      )
    }
  }
}
