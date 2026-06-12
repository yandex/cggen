import Foundation

import CGGenCore
@preconcurrency import Parsing

private enum Tag: String {
  // shape
  case circle, ellipse, polygon, rect, path
  // structural
  case defs, g, svg, use
  // gradient
  case linearGradient, radialGradient
  // descriptive
  case title, desc

  case stop, mask, clipPath, filter

  case feBlend
  case feColorMatrix
  case feComponentTransfer
  case feComposite
  case feConvolveMatrix
  case feDiffuseLighting
  case feDisplacementMap
  case feFlood
  case feGaussianBlur
  case feImage
  case feMerge
  case feMorphology
  case feOffset
  case feSpecularLighting
  case feTile
  case feTurbulence
}

extension SVG.Length {
  public init(_ number: SVG.Float, _ unit: Unit? = nil) {
    self.number = number
    self.unit = unit
  }
}

extension SVG.Length: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(.init(value))
  }
}

// Any parsing failure with the 1-based position of the element or markup
// the parser stopped at.
public struct SVGParsingError: Swift.Error, CustomStringConvertible {
  public var line: Int
  public var column: Int
  public var reason: Swift.Error

  public var description: String {
    "\(line):\(column): \(reason)"
  }
}

public enum SVGParser {
  typealias ShapeParser = SVGShapeParser
  typealias FilterPrimitiveParser = SVGFilterPrimitiveParser
  private typealias RawElement = XMLParsing.RawElement<Node>

  // What an XML node parses into. Stops, filter primitives and text runs
  // are not SVG elements of their own — they only exist as children of
  // specific elements, which unwrap them while the tree is parsed bottom-up.
  private enum Node {
    case element(SVG)
    case stop(SVG.Stop)
    case filterPrimitive(SVG.FilterPrimitiveContent)
    case text(String)
  }

  private enum Error: Swift.Error {
    case expectedSVGTag(got: String)
    case unexpectedXMLText(String)
    case unexpectedChild(String, of: String)
    case childrenNotAllowed(of: String)
    case titleHasInvalidFormat(String)
    case uknownTag(String)
    case notImplemented(String)
  }

  private struct ElementNode: Parser {
    func parse(_ element: inout RawElement) throws -> Node {
      try node(from: &element)
    }
  }

  private struct TextNode: Parser {
    func parse(_ text: inout String) throws -> Node {
      .text(text)
    }
  }

  public static func root(from data: Data) throws -> SVG.Document {
    guard let text = String(data: data, encoding: .utf8) else {
      throw XMLSwiftParsingError(description: "input is not valid UTF-8")
    }
    var input = text[...].utf8
    let document = XMLParsing.DocumentParser(
      element: ElementNode(), text: TextNode()
    )
    let root: Node
    do {
      root = try document.parse(&input)
    } catch {
      let position = XMLParsing.position(ofRemainder: input, in: text)
      throw SVGParsingError(
        line: position.line, column: position.column, reason: error
      )
    }
    switch root {
    case let .element(.svg(document)):
      return document
    case let node:
      let position = try rootElementPosition(in: text)
      throw SVGParsingError(
        line: position.line, column: position.column,
        reason: Error.expectedSVGTag(got: describe(node))
      )
    }
  }

  private static func rootElementPosition(
    in text: String
  ) throws -> (line: Int, column: Int) {
    var input = text[...].utf8
    _ = Optionally { "\u{FEFF}".utf8 }.parse(&input)
    if input.starts(with: "<?xml".utf8) {
      try XMLParsing.Declaration().parse(&input)
    }
    try XMLParsing.Misc().parse(&input)
    return XMLParsing.position(ofRemainder: input, in: text)
  }

  private static func node(from el: inout RawElement) throws -> Node {
    guard let tag = Tag(rawValue: el.tag) else {
      throw Error.uknownTag(el.tag)
    }
    switch tag {
    case .svg:
      return try .element(.svg(document(from: &el)))
    case .g:
      return try .element(.group(group(from: &el)))
    case .defs:
      return try .element(.defs(defs(from: &el)))
    case .rect:
      return try .element(.rect(
        leaf(ShapeParser.rect, .init(data: .init()), &el, tag)
      ))
    case .circle:
      return try .element(.circle(
        leaf(ShapeParser.circle, .init(data: .init()), &el, tag)
      ))
    case .ellipse:
      return try .element(.ellipse(
        leaf(ShapeParser.ellipse, .init(data: .init()), &el, tag)
      ))
    case .polygon:
      return try .element(.polygon(
        leaf(ShapeParser.polygon, .init(data: .init()), &el, tag)
      ))
    case .path:
      return try .element(.path(
        leaf(ShapeParser.path, .init(data: .init()), &el, tag)
      ))
    case .use:
      return try .element(.use(leaf(useSchema, .init(), &el, tag)))
    case .title:
      return try .element(.title(textContent(of: el)))
    case .desc:
      return try .element(.desc(textContent(of: el)))
    case .linearGradient:
      return try .element(.linearGradient(linearGradient(from: &el)))
    case .radialGradient:
      return try .element(.radialGradient(radialGradient(from: &el)))
    case .mask:
      return try .element(.mask(mask(from: &el)))
    case .clipPath:
      return try .element(.clipPath(clipPath(from: &el)))
    case .filter:
      return try .element(.filter(filter(from: &el)))
    case .stop:
      return try .stop(leaf(stopSchema, .init(), &el, tag))
    case .feBlend:
      return try .filterPrimitive(.feBlend(
        leaf(FilterPrimitiveParser.feBlend, .init(data: .init()), &el, tag)
      ))
    case .feColorMatrix:
      return try .filterPrimitive(.feColorMatrix(
        leaf(
          FilterPrimitiveParser.feColorMatrix, .init(data: .init()), &el, tag
        )
      ))
    case .feFlood:
      return try .filterPrimitive(.feFlood(
        leaf(FilterPrimitiveParser.feFlood, .init(data: .init()), &el, tag)
      ))
    case .feGaussianBlur:
      return try .filterPrimitive(.feGaussianBlur(
        leaf(
          FilterPrimitiveParser.feGaussianBlur, .init(data: .init()), &el, tag
        )
      ))
    case .feOffset:
      return try .filterPrimitive(.feOffset(
        leaf(FilterPrimitiveParser.feOffset, .init(data: .init()), &el, tag)
      ))
    case .feComponentTransfer,
         .feComposite,
         .feConvolveMatrix,
         .feDiffuseLighting,
         .feDisplacementMap,
         .feImage,
         .feMerge,
         .feMorphology,
         .feSpecularLighting,
         .feTile,
         .feTurbulence:
      throw Error.notImplemented(el.tag)
    }
  }

  // MARK: - Elements with children

  private static func document(
    from el: inout RawElement
  ) throws -> SVG.Document {
    var document = SVG.Document()
    try documentSchema.parse(el.attrs, into: &document, of: el.tag)
    document.children = try elements(el.children, in: .svg)
    return document
  }

  private static func group(from el: inout RawElement) throws -> SVG.Group {
    var group = SVG.Group()
    try groupSchema.parse(el.attrs, into: &group, of: el.tag)
    group.children = try elements(el.children, in: .g)
    return group
  }

  private static func defs(from el: inout RawElement) throws -> SVG.Defs {
    var defs = SVG.Defs()
    try defsSchema.parse(el.attrs, into: &defs, of: el.tag)
    defs.children = try elements(el.children, in: .defs)
    return defs
  }

  private static func linearGradient(
    from el: inout RawElement
  ) throws -> SVG.LinearGradient {
    var gradient = SVG.LinearGradient()
    try linearGradientSchema.parse(el.attrs, into: &gradient, of: el.tag)
    gradient.stops = try stops(el.children, in: .linearGradient)
    return gradient
  }

  private static func radialGradient(
    from el: inout RawElement
  ) throws -> SVG.RadialGradient {
    var gradient = SVG.RadialGradient()
    try radialGradientSchema.parse(el.attrs, into: &gradient, of: el.tag)
    gradient.stops = try stops(el.children, in: .radialGradient)
    return gradient
  }

  private static func mask(from el: inout RawElement) throws -> SVG.Mask {
    var mask = SVG.Mask()
    try maskSchema.parse(el.attrs, into: &mask, of: el.tag)
    mask.children = try elements(el.children, in: .mask)
    return mask
  }

  private static func clipPath(
    from el: inout RawElement
  ) throws -> SVG.ClipPath {
    var clipPath = SVG.ClipPath()
    try clipPathSchema.parse(el.attrs, into: &clipPath, of: el.tag)
    clipPath.children = try elements(el.children, in: .clipPath)
    return clipPath
  }

  private static func filter(from el: inout RawElement) throws -> SVG.Filter {
    var attrs = SVG.FilterAttributes()
    try filterSchema.parse(el.attrs, into: &attrs, of: el.tag)
    return try .init(
      attributes: attrs,
      children: filterPrimitives(el.children)
    )
  }

  // MARK: - Element schemas

  private typealias Value = SVGValueParser

  private static let documentSchema = AttributeSchema<SVG.Document> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.width, \.width, Value.length)
    $0.field(.height, \.height, Value.length)
    $0.field(.viewBox, \.viewBox, Value.viewBox)
    $0.validate(.version) {
      guard $0 == "1.1" else {
        throw ParseError.consume(expected: "1.1", got: String($0))
      }
    }
    $0.ignore(.xmlns)
    $0.ignore(.xmlnsxlink)
  }

  private static let groupSchema = AttributeSchema<SVG.Group> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
  }

  private static let defsSchema = AttributeSchema<SVG.Defs> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
  }

  private static let useSchema = AttributeSchema<SVG.Use> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.x, \.x, Value.length)
    $0.field(.y, \.y, Value.length)
    $0.field(.width, \.width, Value.length)
    $0.field(.height, \.height, Value.length)
    $0.field(.xlinkHref, \.xlinkHref, Value.iri)
  }

  private static let stopSchema = AttributeSchema<SVG.Stop> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.offset, \.offset, Value.stopOffset)
  }

  private static let linearGradientSchema =
    AttributeSchema<SVG.LinearGradient> {
      $0.core(\.core)
      $0.presentation(\.presentation)
      $0.field(.gradientUnits, \.unit, SVG.Units.parser())
      $0.field(.x1, \.x1, Value.length)
      $0.field(.y1, \.y1, Value.length)
      $0.field(.x2, \.x2, Value.length)
      $0.field(.y2, \.y2, Value.length)
      $0.field(.gradientTransform, \.gradientTransform, Value.transformsList)
    }

  private static let radialGradientSchema =
    AttributeSchema<SVG.RadialGradient> {
      $0.core(\.core)
      $0.presentation(\.presentation)
      $0.field(.gradientUnits, \.unit, SVG.Units.parser())
      $0.field(.cx, \.cx, Value.length)
      $0.field(.cy, \.cy, Value.length)
      $0.field(.r, \.r, Value.length)
      $0.field(.fx, \.fx, Value.length)
      $0.field(.fy, \.fy, Value.length)
      $0.field(.gradientTransform, \.gradientTransform, Value.transformsList)
    }

  private static let maskSchema = AttributeSchema<SVG.Mask> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.x, \.x, Value.length)
    $0.field(.y, \.y, Value.length)
    $0.field(.width, \.width, Value.length)
    $0.field(.height, \.height, Value.length)
    $0.field(.maskUnits, \.maskUnits, SVG.Units.parser())
    $0.field(.maskContentUnits, \.maskContentUnits, SVG.Units.parser())
    $0.ignore(.maskType)
  }

  private static let clipPathSchema = AttributeSchema<SVG.ClipPath> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.transform, \.transform, Value.transformsList)
    $0.field(.clipPathUnits, \.clipPathUnits, SVG.Units.parser())
  }

  private static let filterSchema = AttributeSchema<SVG.FilterAttributes> {
    $0.core(\.core)
    $0.presentation(\.presentation)
    $0.field(.x, \.x, Value.length)
    $0.field(.y, \.y, Value.length)
    $0.field(.width, \.width, Value.length)
    $0.field(.height, \.height, Value.length)
    $0.field(.filterUnits, \.filterUnits, SVG.Units.parser())
  }

  // MARK: - Children helpers

  // An element with no permitted children.
  private static func leaf<State>(
    _ schema: AttributeSchema<State>,
    _ state: State,
    _ el: inout RawElement,
    _ tag: Tag
  ) throws -> State {
    guard el.children.isEmpty else {
      throw Error.childrenNotAllowed(of: tag.rawValue)
    }
    var state = state
    try schema.parse(el.attrs, into: &state, of: el.tag)
    return state
  }

  private static func textContent(of el: RawElement) throws -> String {
    guard case let .text(text)? = el.children.firstAndOnly else {
      throw Error.titleHasInvalidFormat(el.tag)
    }
    return text
  }

  private static func elements(
    _ children: [Node], in tag: Tag
  ) throws -> [SVG] {
    try children.map { child in
      switch child {
      case let .element(element):
        return element
      case let .text(text):
        throw Error.unexpectedXMLText(text)
      case .stop, .filterPrimitive:
        throw Error.unexpectedChild(describe(child), of: tag.rawValue)
      }
    }
  }

  private static func stops(
    _ children: [Node], in tag: Tag
  ) throws -> [SVG.Stop] {
    try children.map { child in
      guard case let .stop(stop) = child else {
        throw Error.unexpectedChild(describe(child), of: tag.rawValue)
      }
      return stop
    }
  }

  private static func filterPrimitives(
    _ children: [Node]
  ) throws -> [SVG.FilterPrimitiveContent] {
    try children.map { child in
      guard case let .filterPrimitive(primitive) = child else {
        throw Error.unexpectedChild(describe(child), of: Tag.filter.rawValue)
      }
      return primitive
    }
  }

  private static func describe(_ node: Node) -> String {
    switch node {
    case let .element(element):
      tagName(of: element)
    case .stop:
      Tag.stop.rawValue
    case .filterPrimitive:
      "filter primitive"
    case .text:
      "text"
    }
  }

  private static func tagName(of element: SVG) -> String {
    let tag: Tag = switch element {
    case .svg: .svg
    case .group: .g
    case .use: .use
    case .path: .path
    case .rect: .rect
    case .circle: .circle
    case .ellipse: .ellipse
    case .polygon: .polygon
    case .mask: .mask
    case .clipPath: .clipPath
    case .defs: .defs
    case .title: .title
    case .desc: .desc
    case .linearGradient: .linearGradient
    case .radialGradient: .radialGradient
    case .filter: .filter
    }
    return tag.rawValue
  }
}

// MARK: - Empty parsing states

extension SVG.CoreAttributes {
  fileprivate init() {
    self.init(id: nil)
  }
}

extension SVG.PresentationAttributes {
  fileprivate init() {
    self.init(
      clipPath: nil,
      clipRule: nil,
      mask: nil,
      filter: nil,
      fill: nil,
      fillRule: nil,
      fillOpacity: nil,
      stroke: nil,
      strokeWidth: nil,
      strokeLineCap: nil,
      strokeLineJoin: nil,
      strokeDashArray: nil,
      strokeDashOffset: nil,
      strokeOpacity: nil,
      strokeMiterlimit: nil,
      opacity: nil,
      stopColor: nil,
      stopOpacity: nil,
      colorInterpolationFilters: nil
    )
  }
}

extension SVG.Document {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(),
      width: nil, height: nil, viewBox: nil, children: []
    )
  }
}

extension SVG.Group {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(), transform: nil, children: []
    )
  }
}

extension SVG.Defs {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(), transform: nil, children: []
    )
  }
}

extension SVG.Use {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(), transform: nil,
      x: nil, y: nil, width: nil, height: nil, xlinkHref: nil
    )
  }
}

extension SVG.Mask {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(), transform: nil,
      x: nil, y: nil, width: nil, height: nil,
      maskUnits: nil, maskContentUnits: nil, children: []
    )
  }
}

extension SVG.ClipPath {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(), transform: nil,
      clipPathUnits: nil, children: []
    )
  }
}

extension SVG.Stop {
  fileprivate init() {
    self.init(core: .init(), presentation: .init(), offset: nil)
  }
}

extension SVG.LinearGradient {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(), unit: nil,
      x1: nil, y1: nil, x2: nil, y2: nil,
      gradientTransform: nil, stops: []
    )
  }
}

extension SVG.RadialGradient {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(), unit: nil,
      cx: nil, cy: nil, r: nil, fx: nil, fy: nil,
      gradientTransform: nil, stops: []
    )
  }
}

extension SVG.FilterAttributes {
  fileprivate init() {
    self.init(
      core: .init(), presentation: .init(),
      x: nil, y: nil, width: nil, height: nil, filterUnits: nil
    )
  }
}

extension SVG.ShapeElement {
  fileprivate init(data: T) {
    self.init(
      core: .init(), presentation: .init(), transform: nil, data: data
    )
  }
}

extension SVG.FilterPrimitiveElement {
  fileprivate init(data: T) {
    self.init(
      core: .init(), presentation: .init(), common: .init(), data: data
    )
  }
}

extension SVG.RectData {
  fileprivate init() {
    self.init(x: nil, y: nil, rx: nil, ry: nil, width: nil, height: nil)
  }
}
