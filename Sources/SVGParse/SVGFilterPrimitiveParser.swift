@preconcurrency import Parsing

enum SVGFilterPrimitiveParser {
  typealias Value = SVGValueParser

  static let feBlend = AttributeSchema<SVG.FeBlend> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.filterPrimitiveCommon(\.common)
    $0.field(.in, \.data.in, Value.filterPrimitiveIn)
    $0.field(.in2, \.data.in2, Value.filterPrimitiveIn)
    $0.field(.mode, \.data.mode, Value.blendMode)
  }

  static let feColorMatrix = AttributeSchema<SVG.FeColorMatrix> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.filterPrimitiveCommon(\.common)
    $0.field(.in, \.data.in, Value.filterPrimitiveIn)
    $0.field(
      .type, \.data.type, SVG.FilterPrimitiveFeColorMatrix.Kind.parser()
    )
    $0.field(.values, \.data.values, Value.listOfNumbers)
  }

  static let feFlood = AttributeSchema<SVG.FeFlood> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.filterPrimitiveCommon(\.common)
    $0.field(.floodColor, \.data.floodColor, Value.rgbcolor)
    $0.field(.floodOpacity, \.data.floodOpacity, Value.number)
  }

  static let feGaussianBlur = AttributeSchema<SVG.FeGaussianBlur> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.filterPrimitiveCommon(\.common)
    $0.field(.in, \.data.in, Value.filterPrimitiveIn)
    $0.field(.stdDeviation, \.data.stdDeviation, Value.numberOptionalNumber)
  }

  static let feOffset = AttributeSchema<SVG.FeOffset> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.filterPrimitiveCommon(\.common)
    $0.field(.in, \.data.in, Value.filterPrimitiveIn)
    $0.field(.dx, \.data.dx, Value.number)
    $0.field(.dy, \.data.dy, Value.number)
  }
}
