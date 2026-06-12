import CGGenCore
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

// MARK: - Attribute Schema

enum SVGAttributeError: Swift.Error {
  case unknown(attribute: String, value: String, element: String)
  case invalid(attribute: String, element: String, reason: Swift.Error)
}

// Parses one element's attributes: each XML attribute selects by name a
// typed value parser writing one field of State, so source order is
// irrelevant and values parse straight from their slice of the document.
// A name the schema doesn't know is an error — every attribute must be
// consumed.
struct AttributeSchema<State>: @unchecked Sendable {
  typealias Value = SVGValueParser

  private var fields: [String: (inout State, Substring) throws -> Void] = [:]

  init(_ configure: (inout Self) -> Void) {
    configure(&self)
  }

  func parse(
    _ attrs: [(name: String, value: Substring)],
    into state: inout State,
    of tag: String
  ) throws {
    for (name, value) in attrs {
      guard let apply = fields[name] else {
        throw SVGAttributeError.unknown(
          attribute: name, value: String(value), element: tag
        )
      }
      do {
        try apply(&state, value)
      } catch {
        throw SVGAttributeError.invalid(
          attribute: name, element: tag, reason: error
        )
      }
    }
  }

  mutating func field<T>(
    _ attribute: Attribute,
    _ keyPath: WritableKeyPath<State, T?>,
    _ value: some Parser<Substring, T>
  ) {
    let parser = value <<~ End()
    fields[attribute.rawValue] = { state, raw in
      state[keyPath: keyPath] = try parser.parse(raw)
    }
  }

  mutating func validate(
    _ attribute: Attribute,
    _ check: @escaping (Substring) throws -> Void
  ) {
    fields[attribute.rawValue] = { _, raw in try check(raw) }
  }

  mutating func ignore(_ attribute: Attribute) {
    fields[attribute.rawValue] = { _, _ in }
  }
}

// MARK: - Shared attribute groups

extension AttributeSchema {
  mutating func core(
    _ keyPath: WritableKeyPath<State, SVG.CoreAttributes>
  ) {
    field(.id, keyPath.appending(path: \.id), Value.identifier)
  }

  mutating func presentation(
    _ keyPath: WritableKeyPath<State, SVG.PresentationAttributes>
  ) {
    field(.clipPath, keyPath.appending(path: \.clipPath), Value.funciri)
    field(
      .clipRule, keyPath.appending(path: \.clipRule), SVG.FillRule.parser()
    )
    field(.mask, keyPath.appending(path: \.mask), Value.funciri)
    field(.filter, keyPath.appending(path: \.filter), Value.funciri)
    field(.fill, keyPath.appending(path: \.fill), Value.paint)
    field(
      .fillRule, keyPath.appending(path: \.fillRule), SVG.FillRule.parser()
    )
    field(.fillOpacity, keyPath.appending(path: \.fillOpacity), Value.number)
    field(.stroke, keyPath.appending(path: \.stroke), Value.paint)
    field(.strokeWidth, keyPath.appending(path: \.strokeWidth), Value.length)
    field(
      .strokeLinecap,
      keyPath.appending(path: \.strokeLineCap),
      SVG.LineCap.parser()
    )
    field(
      .strokeLinejoin,
      keyPath.appending(path: \.strokeLineJoin),
      SVG.LineJoin.parser()
    )
    field(
      .strokeDasharray,
      keyPath.appending(path: \.strokeDashArray),
      Value.dashArray
    )
    field(
      .strokeDashoffset,
      keyPath.appending(path: \.strokeDashOffset),
      Value.length
    )
    field(
      .strokeOpacity, keyPath.appending(path: \.strokeOpacity), Value.number
    )
    field(
      .strokeMiterlimit,
      keyPath.appending(path: \.strokeMiterlimit),
      Value.number
    )
    field(.opacity, keyPath.appending(path: \.opacity), Value.number)
    field(.stopColor, keyPath.appending(path: \.stopColor), Value.rgbcolor)
    field(.stopOpacity, keyPath.appending(path: \.stopOpacity), Value.number)
    field(
      .colorInterpolationFilters,
      keyPath.appending(path: \.colorInterpolationFilters),
      SVG.ColorInterpolation.parser()
    )
  }

  mutating func filterPrimitiveCommon(
    _ keyPath: WritableKeyPath<State, SVG.FilterPrimitiveCommonAttributes>
  ) {
    field(.result, keyPath.appending(path: \.result), Value.identifier)
    field(.height, keyPath.appending(path: \.height), Value.length)
    field(.width, keyPath.appending(path: \.width), Value.length)
    field(.x, keyPath.appending(path: \.x), Value.length)
    field(.y, keyPath.appending(path: \.y), Value.length)
  }
}
