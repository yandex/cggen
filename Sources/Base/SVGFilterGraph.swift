public indirect enum SVGFilterNode: Equatable, Sendable {
  public typealias ColorMatrix = Matrix.D4x5<SVG.Float>
  public enum ColorMatrixType: Equatable, Sendable {
    case matrix(ColorMatrix)
    case saturate(SVG.Float)
    case hueRotate(SVG.Float)
    case luminanceToAlpha
  }

  case flood(color: SVG.Color, opacity: SVG.Float)
  case colorMatrix(in: SVGFilterNode, type: ColorMatrixType)
  case offset(in: SVGFilterNode, dx: SVG.Float, dy: SVG.Float)
  case gaussianBlur(in: SVGFilterNode, stddevX: SVG.Float, stddevY: SVG.Float)
  case blend(in1: SVGFilterNode, in2: SVGFilterNode, mode: SVG.BlendMode)
  case sourceGraphic
  case sourceAlpha
  case backgroundImage
  case backgroundAlpha
  case fillPaint
  case strokePaint
}

private enum FilterGraphCreationError: Swift.Error {
  case inputNotDefined
  case colorMatrixHasInvalidValuesCount(Int)
}

extension SVGFilterNode {
  public init(raw: SVG.Filter) throws {
    let result = try raw.children.reduce(
      into: FilterPrimitiveProcessAccumulator.initial,
      processFilterPrimitive(acc:next:)
    )
    self = result.prev
  }
}

private struct FilterPrimitiveProcessAccumulator: Sendable {
  var prev: SVGFilterNode
  var preceding: [String: SVGFilterNode]

  static let initial =
    FilterPrimitiveProcessAccumulator(prev: .sourceGraphic, preceding: [:])
}

private func processFilterPrimitive(
  acc: inout FilterPrimitiveProcessAccumulator,
  next: SVG.FilterPrimitiveContent
) throws {
  let nodeFromInput = node(acc: acc)
  let resultNode: SVGFilterNode

  switch next {
  case let .feBlend(d):
    let in1 = try d.in |> nodeFromInput
    let in2 = try d.in2 |> nodeFromInput
    let mode = d.mode ?? .normal
    resultNode = .blend(in1: in1, in2: in2, mode: mode)
  case let .feColorMatrix(d):
    let input = try d.in |> nodeFromInput
    let type: SVGFilterNode.ColorMatrixType
    switch d.type ?? .matrix {
    case .matrix:
      let matrix = try d.values.map(colorMatrixFromValues(values:))
        ?? Matrix.scalar4x5(λ: 1, zero: 0)
      type = .matrix(matrix)
    case .saturate:
      type = try .saturate(d.values.map(singleFromValues) ?? 1)
    case .hueRotate:
      type = try .hueRotate(d.values.map(singleFromValues) ?? 1)
    case .luminanceToAlpha:
      type = .luminanceToAlpha
    }
    resultNode = .colorMatrix(in: input, type: type)
  case let .feFlood(d):
    resultNode =
      .flood(color: d.floodColor ?? .black(), opacity: d.floodOpacity ?? 1)
  case let .feGaussianBlur(d):
    let stddevX = d.stdDeviation?._1 ?? 0
    let stddevY = d.stdDeviation?._2 ?? stddevX
    resultNode = try .gaussianBlur(
      in: d.in |> nodeFromInput,
      stddevX: stddevX,
      stddevY: stddevY
    )
  case let .feOffset(d):
    resultNode = try .offset(
      in: d.in |> nodeFromInput,
      dx: d.dx ?? 0, dy: d.dy ?? 0
    )
  }
  acc.prev = resultNode
  if let result = next.common.result {
    acc.preceding[result] = resultNode
  }
}

private func singleFromValues(values: [SVG.Float]) throws -> SVG.Float {
  try check(values.count == 1, .colorMatrixHasInvalidValuesCount(values.count))
  return values[0]
}

private func colorMatrixFromValues(
  values: [SVG.Float]
) throws -> SVGFilterNode.ColorMatrix {
  try check(values.count == 20, .colorMatrixHasInvalidValuesCount(values.count))
  let a = values.splitBy(subSize: 5).map(Array.init)
  return .init(
    r1: .init(c1: a[0][0], c2: a[0][1], c3: a[0][2], c4: a[0][3], c5: a[0][4]),
    r2: .init(c1: a[1][0], c2: a[1][1], c3: a[1][2], c4: a[1][3], c5: a[1][4]),
    r3: .init(c1: a[2][0], c2: a[2][1], c3: a[2][2], c4: a[2][3], c5: a[2][4]),
    r4: .init(c1: a[3][0], c2: a[3][1], c3: a[3][2], c4: a[3][3], c5: a[3][4])
  )
}

/*
 15.7.2
 Identifies input for the given filter primitive.
 The value can be either one of six keywords or can be a string which matches a
 previous ‘result’ attribute value within the same ‘filter’ element. If no value
 is provided and this is the first filter primitive, then this filter primitive
 will use SourceGraphic as its input. If no value is provided and this is
 a subsequent filter primitive, then this filter primitive will use the result
 from the previ- ous filter primitive as its input.

 If the value for ‘result’ appears multiple times within a given ‘filter’
 element, then a reference to that result will use the closest preceding filter
 primitive with the given value for attribute ‘result’. Forward references to
 results are an error.
 */
private func node(
  acc: FilterPrimitiveProcessAccumulator
) -> (SVG.FilterPrimitiveIn?) throws -> SVGFilterNode { {
  switch $0 {
  case let .predefined(predefined):
    return node(from: predefined)
  case let .previous(name):
    return try acc.preceding[name] !! FilterGraphCreationError.inputNotDefined
  case .none:
    return acc.prev
  }
} }

private func node(
  from predefinedInput: SVG.FilterPrimitiveIn.Predefined
) -> SVGFilterNode {
  switch predefinedInput {
  case .backgroundalpha:
    return .backgroundAlpha
  case .sourcegraphic:
    return .sourceGraphic
  case .sourcealpha:
    return .sourceAlpha
  case .backgroundimage:
    return .backgroundImage
  case .fillpaint:
    return .fillPaint
  case .strokepaint:
    return .strokePaint
  }
}

private func check(
  _ condition: Bool,
  _ error: FilterGraphCreationError
) throws {
  if !condition {
    throw error
  }
}

extension SVG.FilterPrimitiveContent {
  public var common: SVG.FilterPrimitiveCommonAttributes {
    switch self {
    case let .feBlend(d):
      return d.common
    case let .feColorMatrix(d):
      return d.common
    case let .feFlood(d):
      return d.common
    case let .feGaussianBlur(d):
      return d.common
    case let .feOffset(d):
      return d.common
    }
  }
}
