@preconcurrency import Parsing

public enum SVGAttributeParsers {
  typealias Parser<T> = Base.Parser<Substring, T>
  public typealias NewParser<T> = Base.NewParser<Substring, T>

  static let comma: String = ","
  static let wsps = [0x20, 0x9, 0xD, 0xA].map { String.UTF8View([$0]) }
  static let wsp = From(.utf8) { OneOf {
    for s in wsps {
      s
    }
  }}

  // (wsp+ comma? wsp*) | (comma wsp*)
  nonisolated(unsafe)
  static let commaWsp: some NewParser<Void> =
    (wsp+ ~>> comma~? ~>> wsp* | comma ~>> wsp*).map(always(()))
  nonisolated(unsafe)
  static let number: some NewParser<SVG.Float> =
    From(.utf8) { SVG.Float.parser() }
  static let listOfNumbers = zeroOrMore(number, separator: commaWsp)
  nonisolated(unsafe)
  static let numberOptionalNumber: some NewParser<SVG.NumberOptionalNumber> = Parse {
    SVG.NumberOptionalNumber(_1: $0.0, _2: $0.1)
  } with: {
    number
    (commaWsp ~>> number)~?
  }
  nonisolated(unsafe)
  static let coord: some NewParser<SVG.Float> = number

  nonisolated(unsafe)
  static let lengthUnit: some NewParser<SVG.Length.Unit> = SVG.Length.Unit.parser()
  nonisolated(unsafe)
  static let length: some NewParser<SVG.Length> = (number ~ lengthUnit~?)
    .map { SVG.Length(number: $0.0, unit: $0.1) }
  nonisolated(unsafe)
  static let flag: some NewParser<Bool> =
    OneOf {
      "0".map(always(false))
      "1".map(always(true))
    }

  nonisolated(unsafe)
  static let viewBox: some NewParser<SVG.ViewBox> =
    zip(
      number <<~ commaWsp, number <<~ commaWsp, number <<~ commaWsp, number,
      with: SVG.ViewBox.init
    )

  // Has no equivalent in specification, for code deduplication only.
  // "$name" wsp* "(" wsp* parser wsp* ")"
  static func namedTransform(
    _ name: String,
    _ value: some NewParser<SVG.Transform>
  ) -> some NewParser<SVG.Transform> {
    (name ~ wsp* ~ "(" ~ wsp*) ~>> value <<~ (wsp* ~ ")")
  }

  // "translate" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  nonisolated(unsafe)
  static let translate: some NewParser<SVG.Transform> = namedTransform(
    "translate",
    zip(number, (commaWsp ~>> number)~?, with: SVG.Transform.translate)
  )

  // "scale" wsp* "(" wsp* number ( comma-wsp number )? wsp* ")"
  nonisolated(unsafe)
  static let scale: some NewParser<SVG.Transform> = namedTransform(
    "scale",
    zip(number, (commaWsp ~>> number)~?, with: SVG.Transform.scale)
  )

  // comma-wsp number comma-wsp number
  nonisolated(unsafe)
  private static let anchor: some NewParser<SVG.Transform.Anchor> = Parse { values -> SVG.Transform.Anchor in
    SVG.Transform.Anchor(cx: values.0, cy: values.1)
  } with: {
    commaWsp ~>> number
    commaWsp ~>> number
  }

  nonisolated(unsafe)
  private static let angle: some NewParser<SVG.Angle> =
    number.map(SVG.Angle.init)

  // "rotate" wsp* "(" wsp* number ( comma-wsp number comma-wsp number )? wsp*
  // ")"
  nonisolated(unsafe)
  static let rotate: some NewParser<SVG.Transform> = namedTransform(
    "rotate",
    zip(angle, anchor~?, with: SVG.Transform.rotate)
  )

  // "skewX" wsp* "(" wsp* number wsp* ")"
  nonisolated(unsafe)
  static let skewX: some NewParser<SVG.Transform> = namedTransform(
    "skewX", angle.map(SVG.Transform.skewX)
  )
  // "skewX" wsp* "(" wsp* number wsp* ")"
  nonisolated(unsafe)
  static let skewY: some NewParser<SVG.Transform> = namedTransform(
    "skewY", angle.map(SVG.Transform.skewY)
  )

  /*
   "matrix" wsp* "(" wsp*
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number comma-wsp
      number wsp* ")"
   */
  nonisolated(unsafe)
  static let matrix: some NewParser<SVG.Transform> = namedTransform(
    "matrix", zip(
      number <<~ commaWsp,
      number <<~ commaWsp,
      number <<~ commaWsp,
      number <<~ commaWsp,
      number <<~ commaWsp,
      number,
      with: SVG.Transform.matrix
    )
  )

  nonisolated(unsafe)
  static let transformsList: some NewParser<[SVG.Transform]> =
    wsp* ~>> oneOrMore(transform, separator: commaWsp+) <<~ wsp*
  nonisolated(unsafe)
  static let transform: some NewParser<SVG.Transform> = OneOf {
    translate
    scale
    rotate
    skewX
    skewY
    matrix
  }

  nonisolated(unsafe)
  static let hexByteFromSingle: some NewParser<UInt8> = First().oldParser.flatMap {
    guard let value = hexFromChar($0) else { return .never() }
    return .always(value << 4 | value)
  }

  nonisolated(unsafe)
  static let hexByte: some NewParser<UInt8> = (First() ~ First()).oldParser.flatMap {
    guard let v1 = hexFromChar($0.0),
          let v2 = hexFromChar($0.1) else { return .never() }
    return .always(v1 << 4 | v2)
  }

  nonisolated(unsafe)
  private static let shortRGB: some NewParser<SVG.Color> = Parse { values -> SVG.Color in
    SVG.Color(red: values.0, green: values.1, blue: values.2)
  } with: {
    hexByteFromSingle
    hexByteFromSingle
    hexByteFromSingle
  }
  
  nonisolated(unsafe)
  private static let rgb: some NewParser<SVG.Color> = Parse { values -> SVG.Color in
    SVG.Color(red: values.0, green: values.1, blue: values.2)
  } with: {
    hexByte
    hexByte
    hexByte
  }

  nonisolated(unsafe)
  public static let rgbcolor: some NewParser<SVG.Color> = OneOf {
    "#" ~>> (rgb | shortRGB)
    SVGColorKeyword.parser().map(\.color)
  }

  nonisolated(unsafe)
  static let iri: some NewParser<String> =
    "#" ~>> consume(while: always(true)).map(String.init)
  nonisolated(unsafe)
  static let funciri: some NewParser<String> =
    "url(#" ~>> consume(while: { $0 != ")" }).map(String.init) <<~ ")"

  nonisolated(unsafe)
  static let paint: some NewParser<SVG.Paint> =
    "none".map(always(.none)) |
    rgbcolor.map(SVG.Paint.rgb) |
    funciri.map(SVG.Paint.funciri(id:))

  // coordinate comma-wsp coordinate
  // | coordinate negative-coordinate
  nonisolated(unsafe)
  static let coordinatePair: some NewParser<SVG.CoordinatePair> = Parse {
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
  nonisolated(unsafe)
  static let listOfPoints: some NewParser<SVG.CoordinatePairs> =
    wsp* ~>> zeroOrMore(coordinatePair, separator: commaWsp) <<~ wsp*

  // elliptical-arc-argument:
  //   nonnegative-number comma-wsp? nonnegative-number comma-wsp?
  //     number comma-wsp flag comma-wsp? flag comma-wsp? coordinate-pair
  nonisolated(unsafe)
  static let ellipticalArcArg: some NewParser<SVG.PathData.EllipticalArcArgument> = zip(
    number, commaWsp~? ~>> number, commaWsp~? ~>> number, 
    commaWsp ~>> flag, commaWsp~? ~>> flag, commaWsp~? ~>> coordinatePair
  ) { rx, ry, xAxisRotation, largeArcFlag, sweepFlag, end in
    SVG.PathData.EllipticalArcArgument(
      rx: rx, 
      ry: ry, 
      xAxisRotation: xAxisRotation, 
      largeArcFlag: largeArcFlag, 
      sweepFlag: sweepFlag, 
      end: end
    )
  }

  nonisolated(unsafe) static let identifier: some NewParser<String> =
    Rest().map(String.init)

  nonisolated(unsafe)
  static let stopOffset: some NewParser<SVG.Stop.Offset> = zip(
    number, "%"~?
  ) { num, percentSign in
    percentSign != nil ? .percentage(num) : .number(num)
  }

  // MARK: Path

  nonisolated(unsafe)
  private static let anyCommand: some NewParser<SVG.PathData.Command> = OneOf {
    command("M", arg: coordinatePair) { .moveto($0) }
    command("L", arg: coordinatePair) { .lineto($0) }
    command("H", arg: coord) { .horizontalLineto($0) }
    command("V", arg: coord) { .verticalLineto($0) }
    command("C", arg: curveArgument) { .curveto($0) }
    command("S", arg: smoothCurveArgument) { .smoothCurveto($0) }
    command("Q", arg: quadraticCurveArgument) { .quadraticBezierCurveto($0) }
    command("T", arg: coordinatePair) { .smoothQuadraticBezierCurveto(to: $0) }
    command("A", arg: ellipticalArcArg) { .ellipticalArc($0) }
    positioning(of: "Z").map { .init(positioning: $0, kind: .closepath) }
  }

  nonisolated(unsafe)
  static let pathData: some NewParser<[SVG.PathData.Command]> =
    wsp* ~>> oneOrMore(anyCommand, separator: wsp*) <<~ wsp*

  nonisolated(unsafe)
  private static let quadraticCurveArgument: some NewParser<SVG.PathData.QuadraticCurveArgument> = Parse {
    SVG.PathData.QuadraticCurveArgument(cp1: $0.0, to: $0.1)
  } with: {
    coordinatePair <<~ commaWsp~?
    coordinatePair
  }

  nonisolated(unsafe)
  private static let smoothCurveArgument: some NewParser<SVG.PathData.SmoothCurveArgument> = Parse {
    SVG.PathData.SmoothCurveArgument(cp2: $0.0, to: $0.1)
  } with: {
    coordinatePair <<~ commaWsp~?
    coordinatePair
  }

  nonisolated(unsafe)
  private static let curveArgument: some NewParser<SVG.PathData.CurveArgument> = Parse {
    SVG.PathData.CurveArgument(cp1: $0.0, cp2: $0.1, to: $0.2)
  } with: {
    coordinatePair <<~ commaWsp~?
    coordinatePair <<~ commaWsp~?
    coordinatePair
  }

  private static func command<T>(
    _ cmd: Character,
    arg: some NewParser<T>,
    builder: @escaping ([T]) -> SVG.PathData.CommandKind
  ) -> some NewParser<SVG.PathData.Command> {
    Parse {
      SVG.PathData.Command(positioning: $0.0, kind: builder($0.1))
    } with: {
      positioning(of: cmd) <<~ wsp*
      argumentSequence(arg)
    }
  }

  private static func positioning(
    of cmd: Character
  ) -> some NewParser<SVG.PathData.Positioning> {
    cmd.lowercased().map(always(.relative))
      | cmd.uppercased().map(always(.absolute))
  }

  private static func argumentSequence<T>(_ p: some NewParser<T>) -> some NewParser<[T]> {
    Many(1...) {
      p
    } separator: {
      commaWsp~?
    }
  }

  private static func hexFromChar(_ c: Character) -> UInt8? {
    c.hexDigitValue.flatMap(UInt8.init(exactly:))
  }

  // Dash Array
  nonisolated(unsafe)
  static let dashArray: some NewParser<[SVG.Length]> = 
    Many(1...) {
      length
    } separator: {
      commaWsp
    }

  nonisolated(unsafe)
  private static let filterPrimitiveInPredefined:
  some NewParser<SVG.FilterPrimitiveIn.Predefined> = SVG.FilterPrimitiveIn.Predefined.parser()

  nonisolated(unsafe)
  static let filterPrimitiveIn: some NewParser<SVG.FilterPrimitiveIn> = Rest().map { substring in
    let value = String(substring)
    return SVG.FilterPrimitiveIn.Predefined(rawValue: value)
      .map(SVG.FilterPrimitiveIn.predefined) ?? .previous(value)
  }

  nonisolated(unsafe)
  static let blendMode: some NewParser<SVG.BlendMode> = SVG.BlendMode.parser()
}
