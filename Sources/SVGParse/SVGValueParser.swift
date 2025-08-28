import CGGenCore
@preconcurrency import Parsing

public enum SVGValueParser {
  static let comma: String = ","
  static let wsp = From(.utf8) { OneOf {
    for s in [0x20, 0x9, 0xD, 0xA] as [UInt8] {
      String.UTF8View([s])
    }
  }}

  // (wsp+ comma? wsp*) | (comma wsp*)
  struct CommaWSP: Parser {
    var body: some Parser<Substring, Void> {
      Skip { wsp+ ~>> comma~? ~>> wsp* | comma ~>> wsp* }
    }
  }
  
  static let commaWsp = CommaWSP()
  static let number =
    From(.utf8) { SVG.Float.parser() }
  static let listOfNumbers = Many { number } separator: { commaWsp }
  static let numberOptionalNumber = Parse {
    SVG.NumberOptionalNumber(_1: $0.0, _2: $0.1)
  } with: {
    number
    (commaWsp ~>> number)~?
  }

  static let coord = number

  static let lengthUnit = SVG.Length.Unit.parser(of: Substring.self)
  static let length = Parse(SVG.Length.init(number:unit:)) {
    number
    Optionally { lengthUnit }
  }

  static let flag =
    OneOf {
      "0".flatMap { Always(false) }
      "1".flatMap { Always(true) }
    }

  static let viewBox = Parse(SVG.ViewBox.init) {
    number <<~ commaWsp
    number <<~ commaWsp
    number <<~ commaWsp
    number
  }

  // "$name" wsp* "(" wsp* parser wsp* ")"
  struct NamedTransform<P: Parser & Sendable>: Parser, Sendable
    where P.Input == Substring {
    var name: String
    var parser: Parsers.Map<P, SVG.Transform>

    init(
      _ name: String,
      _ transform: @escaping @Sendable (P.Output) -> SVG.Transform,
      @ParserBuilder<Input> _ parser: () -> P
    ) where P.Input == Substring {
      self.name = name
      self.parser = parser().map(transform)
    }

    var body: some Parsing.Parser<Substring, SVG.Transform> {
      Parse {
        Skip {
          name
          wsp*
          "("
          wsp*
        }
        parser
        Skip {
          wsp*
          ")"
        }
      }
    }
  }

  // "translate" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  static let translate = NamedTransform("translate", SVG.Transform.translate) {
    number
    (commaWsp~? ~>> number)~?
  }

  // "scale" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  static let scale = NamedTransform("scale", SVG.Transform.scale) {
    number
    (commaWsp~? ~>> number)~?
  }

  // comma-wsp number comma-wsp number
  private static let anchor = Parse(SVG.Transform.Anchor.init) {
    commaWsp ~>> number
    commaWsp ~>> number
  }

  private static let angle = number.map(SVG.Angle.init)

  // "rotate" wsp* "(" wsp* number ( comma-wsp number comma-wsp number )? wsp*
  // ")"
  static let rotate = NamedTransform("rotate", SVG.Transform.rotate) {
    number.map(SVG.Angle.init)
    Parse { (values: (SVG.Float?, SVG.Float?)) -> SVG.Transform.Anchor? in
      if let cx = values.0, let cy = values.1 {
        return SVG.Transform.Anchor(cx: cx, cy: cy)
      }
      return nil
    } with: {
      (commaWsp ~>> number)~?
      (commaWsp ~>> number)~?
    }
  }

  // "skewX" wsp* "(" wsp* number wsp* ")"
  static let skewX = NamedTransform("skewX", SVG.Transform.skewX) {
    number.map(SVG.Angle.init)
  }

  // "skewY" wsp* "(" wsp* number wsp* ")"
  static let skewY = NamedTransform("skewY", SVG.Transform.skewY) {
    number.map(SVG.Angle.init)
  }

  /*
   "matrix" wsp* "(" wsp*
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number wsp* ")"
   */
  static let matrix = NamedTransform("matrix", SVG.Transform.matrix) {
    Parse { values -> (
      SVG.Float,
      SVG.Float,
      SVG.Float,
      SVG.Float,
      SVG.Float,
      SVG.Float
    ) in
      (values.0, values.1, values.2, values.3, values.4, values.5)
    } with: {
      number <<~ commaWsp
      number <<~ commaWsp
      number <<~ commaWsp
      number <<~ commaWsp
      number <<~ commaWsp
      number
    }
  }

  static let transformsList = Parse {
    Skip { wsp* }
    Many(1...) {
      transform
    } separator: {
      commaWsp+
    }
    Skip { wsp* }
  }

  struct Transform: Parser {
    var body: some Parser<Substring, SVG.Transform> {
      OneOf {
        translate
        scale
        rotate
        skewX
        skewY
        matrix
      }
    }
  }
  
  static let transform = Transform()

  static let hexByteFromSingle = First().flatMap {
    if let value = hexFromChar($0) {
      Always<Substring, UInt8>(value << 4 | value)
    } else {
      Fail<Substring, UInt8>()
    }
  }

  static let hexByte = (First<Substring>() ~ First<Substring>())
    .compactMap { (chars: (
      Character,
      Character
    )) -> UInt8? in
      guard let v1 = chars.0.hexDigitValue,
            let v2 = chars.1.hexDigitValue else { return nil }
      return UInt8(v1 << 4 | v2)
    }

  private static let shortRGB = Parse { values -> SVG.Color in
    SVG.Color(red: values.0, green: values.1, blue: values.2)
  } with: {
    hexByteFromSingle
    hexByteFromSingle
    hexByteFromSingle
  }

  private static let rgb = Parse { values -> SVG.Color in
    SVG.Color(red: values.0, green: values.1, blue: values.2)
  } with: {
    hexByte
    hexByte
    hexByte
  }

  public struct RGBColor: Parser, Sendable {
    public init() {}
    
    public var body: some Parser<Substring, SVG.Color> {
      OneOf {
        "#" ~>> (rgb | shortRGB)
        SVGColorKeyword.parser().map(\.color)
      }
    }
  }
  
  public static let rgbcolor = RGBColor()

  static let iri =
    "#" ~>> Rest().map(String.init)
  static let funciri =
    "url(#" ~>> Prefix(while: { $0 != ")" }).map(String.init) <<~ ")"

  struct Paint: Parser {
    var body: some Parser<Substring, SVG.Paint> {
      OneOf {
        "none".map(always(SVG.Paint.none))
        rgbcolor.map(SVG.Paint.rgb)
        funciri.map(SVG.Paint.funciri(id:))
      }
    }
  }
  
  static let paint = Paint()

  // Add miter limit parser
  static let miterLimit = number

  // coordinate comma-wsp coordinate
  // | coordinate negative-coordinate
  static let coordinatePair = Parse {
    SVG.CoordinatePair(($0.0, $0.1))
  } with: {
    number
    commaWsp~? ~>> number
  }

  // list-of-points:
  //   wsp* coordinate-pairs? wsp*
  // coordinate-pairs:
  //   coordinate-pair
  //   | coordinate-pair comma-wsp coordinate-pairs
  static let listOfPoints = Parse {
    Skip { wsp* }
    Many { coordinatePair } separator: { commaWsp }
    Skip { wsp* }
  }

  // elliptical-arc-argument:
  //   nonnegative-number comma-wsp? nonnegative-number comma-wsp?
  //     number comma-wsp flag comma-wsp? flag comma-wsp? coordinate-pair
  struct EllipticalArcArg: Parser {
    var body: some Parser<Substring, SVG.PathData.EllipticalArcArgument> {
      Parse(SVG.PathData.EllipticalArcArgument.init) {
        number
        commaWsp~? ~>> number
        commaWsp~? ~>> number
        commaWsp ~>> flag
        commaWsp~? ~>> flag
        commaWsp~? ~>> coordinatePair
      }
    }
  }
  
  static let ellipticalArcArg = EllipticalArcArg()

  static let identifier = Rest<Substring>().map(String.init)

  static let stopOffset = Parse { num, percentSign in
    percentSign != nil ? SVG.Stop.Offset.percentage(num) : .number(num)
  } with: {
    number
    "%"~?
  }

  // MARK: Path

  struct Command<P: Parser & Sendable>: Parser where P.Input == Substring {
    var cmd: Character
    var arg: P
    var transform: ([P.Output]) -> SVG.PathData.CommandKind

    init(
      _ cmd: Character,
      arg: P,
      transform: @escaping ([P.Output]) -> SVG.PathData.CommandKind
    ) {
      self.cmd = cmd
      self.arg = arg
      self.transform = transform
    }

    var body: some Parsing.Parser<Substring, SVG.PathData.Command> {
      Parse {
        SVG.PathData.Command(positioning: $0.0, kind: transform($0.1))
      } with: {
        Positioning(of: cmd) <<~ wsp*
        ArgumentSequence(arg)
      }
    }
  }

  private struct AnyCommand: Parser {
    var body: some Parser<Substring, SVG.PathData.Command> {
      OneOf {
        Command("M", arg: coordinatePair) { .moveto($0) }
        Command("L", arg: coordinatePair) { .lineto($0) }
        Command("H", arg: coord) { .horizontalLineto($0) }
        Command("V", arg: coord) { .verticalLineto($0) }
        Command("C", arg: curveArgument) { .curveto($0) }
        Command("S", arg: smoothCurveArgument) { .smoothCurveto($0) }
        Command("Q", arg: quadraticCurveArgument) { .quadraticBezierCurveto($0) }
        Command("T", arg: coordinatePair) { .smoothQuadraticBezierCurveto(to: $0) }
        Command("A", arg: ellipticalArcArg) { .ellipticalArc($0) }
        Positioning(of: "Z").map { .init(positioning: $0, kind: .closepath) }
      }
    }
  }
  
  private static let anyCommand = AnyCommand()

  struct PathData: Parser {
    var body: some Parser<Substring, [SVG.PathData.Command]> {
      wsp* ~>> Many(1...) { anyCommand } separator: { wsp* } <<~ wsp*
    }
  }
  
  static let pathData = PathData()

  private struct QuadraticCurveArgument: Parser {
    var body: some Parser<Substring, SVG.PathData.QuadraticCurveArgument> {
      Parse {
        SVG.PathData.QuadraticCurveArgument(cp1: $0.0, to: $0.1)
      } with: {
        coordinatePair <<~ commaWsp~?
        coordinatePair
      }
    }
  }
  
  private static let quadraticCurveArgument = QuadraticCurveArgument()

  private struct SmoothCurveArgument: Parser {
    var body: some Parser<Substring, SVG.PathData.SmoothCurveArgument> {
      Parse {
        SVG.PathData.SmoothCurveArgument(cp2: $0.0, to: $0.1)
      } with: {
        coordinatePair <<~ commaWsp~?
        coordinatePair
      }
    }
  }
  
  private static let smoothCurveArgument = SmoothCurveArgument()

  private struct CurveArgument: Parser {
    var body: some Parser<Substring, SVG.PathData.CurveArgument> {
      Parse {
        SVG.PathData.CurveArgument(cp1: $0.0, cp2: $0.1, to: $0.2)
      } with: {
        coordinatePair <<~ commaWsp~?
        coordinatePair <<~ commaWsp~?
        coordinatePair
      }
    }
  }
  
  private static let curveArgument = CurveArgument()

  struct Positioning: Parser, Sendable {
    var cmd: Character

    init(of cmd: Character) {
      self.cmd = cmd
    }

    var body: some Parser<Substring, SVG.PathData.Positioning> {
      cmd.lowercased().map(always(SVG.PathData.Positioning.relative))
        | cmd.uppercased().map(always(.absolute))
    }
  }

  private struct ArgumentSequence<P: Parser & Sendable>: Parser, Sendable
    where P.Input == Substring {
    var parser: P

    init(_ parser: P) {
      self.parser = parser
    }

    var body: some Parser<Substring, [P.Output]> {
      Many(1...) { parser } separator: { commaWsp~? }
    }
  }

  private static func hexFromChar(_ c: Character) -> UInt8? {
    c.hexDigitValue.flatMap(UInt8.init(exactly:))
  }

  // Dash Array
  static let dashArray =
    Many(1...) {
      length
    } separator: {
      commaWsp
    }

  private static let filterPrimitiveInPredefined =
    SVG.FilterPrimitiveIn.Predefined.parser(of: Substring.self)

  static let filterPrimitiveIn = Rest().map { (substring: Substring) in
    let value = String(substring)
    return SVG.FilterPrimitiveIn.Predefined(rawValue: value)
      .map(SVG.FilterPrimitiveIn.predefined) ?? .previous(value)
  }

  static let blendMode = SVG.BlendMode.parser(of: Substring.self)
}
