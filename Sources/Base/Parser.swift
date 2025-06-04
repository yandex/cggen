import Darwin

@preconcurrency import Parsing

precedencegroup StreamAddition {
  higherThan: AdditionPrecedence
  associativity: right
}

precedencegroup StreamLeft {
  higherThan: StreamAddition
  associativity: left
}

precedencegroup StreamRight {
  higherThan: StreamLeft
  associativity: right
}

precedencegroup StreamOptional {
  higherThan: StreamRight
  associativity: right
}

// Performs zip on two operands with map droping rhs
infix operator ~>>: StreamRight
// Performs zip on two operands with map droping lhs
infix operator <<~: StreamLeft
// Equivalent to zip(rhs, lhs)
infix operator ~: StreamAddition

// "Zero or more"
postfix operator *
// "One or more"
postfix operator +
// "Zero or one"
postfix operator ~?

public typealias NewParser = Parsing.Parser

public struct AdhocParser<Input, Output>: NewParser {
  public var parseImpl: @Sendable (inout Input) -> Result<Output, Error>

  public init(_ parse: @escaping @Sendable (inout Input) -> Result<
    Output,
    Error
  >) {
    parseImpl = parse
  }

  public func parse(_ input: inout Input) throws -> Output {
    try parseImpl(&input).get()
  }
}

extension NewParser {
  public var oldParser: OldParser<Input, Output> {
    .init(self)
  }
}

public struct OldParser<D, T>: Parsing.Parser, @unchecked Sendable {
  public typealias Input = D
  public typealias Output = T

  public struct GenericError: Error, @unchecked Sendable {
    public var text: D

    var localizedDescription: String {
      "Couldn't parse \(T.self) from <\(text)>"
    }

    @inlinable
    public init(_ text: D) {
      self.text = text
    }
  }

  public typealias Error = Swift.Error

  public var newParser: any NewParser<D, T>

  public func parse(_ input: inout D) throws -> T {
    try newParser.parse(&input)
  }

  @inlinable
  public func run(_ data: inout D) -> T? {
    try? newParser.parse(&data)
  }

  @inlinable
  public func run(_ data: D) -> Result<T, Error> {
    Result {
      var copy = data
      return try newParser.parse(&copy)
    }
  }

  @inlinable
  public func tempRun(_ data: inout D) -> Result<T, Error> {
    Result {
      try newParser.parse(&data)
    }
  }

  @inlinable
  public init(_ parse: @escaping @Sendable (inout D) -> Result<T, Error>) {
    newParser = AdhocParser(parse)
  }

  @inlinable
  public init(_ p: any NewParser<D, T>) {
    newParser = p
  }

  @inlinable
  public static func opt(
    parse: @escaping @Sendable (inout D) -> T?
  ) -> OldParser<D, T> {
    .init {
      .init(optional: parse(&$0), or: GenericError($0))
    }
  }

  @inlinable
  public static func always(_ t: T) -> OldParser<D, T> {
    .init(Base.always(.success(t)))
  }

  @inlinable
  public static func never() -> OldParser<D, T> {
    .init(Base.always(.failure(ParseError.never)))
  }

  @inlinable
  public var optional: OldParser<D?, T> {
    .init {
      guard var datum = $0 else {
        return .failure(ParseError.gotNilExpected(type: D.self))
      }
      let result = self.tempRun(&datum)
      return result
    }
  }

  @inlinable
  public func map<T1>(
    _ t: @Sendable @escaping (T) -> T1
  ) -> OldParser<D, T1> {
    .init { self.tempRun(&$0).map(t) }
  }

  @inlinable
  public func flatMap<T1>(
    _ t: @Sendable @escaping (T) -> (OldParser<D, T1>)
  ) -> OldParser<D, T1> {
    OldParser<D, T1> { data in
      let original = data
      let res = self.tempRun(&data).flatMap { t($0).tempRun(&data) }
      res.onFailure { data = original }
      return res
    }
  }

  @inlinable
  public func flatMapResult<T1>(
    _ t: @Sendable @escaping (T) -> (Result<T1, Error>)
  ) -> OldParser<D, T1> {
    OldParser<D, T1> { data in
      self.tempRun(&data).flatMap(t)
    }
  }
}

extension AdhocParser: @unchecked Sendable where Input: Sendable,
  Output: Sendable {}

extension OldParser where D == T, D: RangeReplaceableCollection {
  @inlinable
  public static func identity() -> OldParser<D, D> {
    .init { data in
      defer { data.removeAll(keepingCapacity: false) }
      return .success(data)
    }
  }
}

extension OldParser where D: Collection, D.SubSequence == D {
  static func next(
    _ parse: @escaping (D.Element) -> Result<T, Error>
  ) -> OldParser<D, T> {
    let parse = unsafeBitCast(
      parse, to: (@Sendable (D.Element) -> Result<T, Error>).self
    )
    return .init { data in
      let initial = data
      guard let next = data.popFirst() else {
        return .failure(ParseError.atLeastOneExpected)
      }
      let result = parse(next)
      result.onFailure { data = initial }
      return result
    }
  }
}

extension OldParser where D == T? {
  static func unwrap() -> OldParser<D, T> {
    fatalError()
  }
}


struct DicitionaryKey<Key: Hashable, Value>: NewParser {
  var key: Key

  init(_ key: Key) {
    self.key = key
  }

  func parse(_ input: inout [Key: Value]) throws -> Value? {
    input.removeValue(forKey: key)
  }
}

public enum ParseError: Error {
  case atLeastOneExpected
  case consume(expected: String, got: String)
  case never
  case couldntConvertStringTo(type: String)
  case parsingNotComplete(left: String)
  case gotNilExpected(String)

  @inlinable
  public static func gotNilExpected<T>(type: T.Type) -> ParseError {
    .gotNilExpected(String(describing: type))
  }
}

@inlinable
public func ~>> <P1: NewParser, P2: NewParser>(
  lhs: P1, rhs: P2
) -> Parse<P1.Input, ParserBuilder<P1.Input>.SkipFirst<
  Skip<P1.Input, P1>,
  P2
>> {
  Parse {
    Skip { lhs }
    rhs
  }
}

@inlinable
public func <<~< P1: NewParser, P2: NewParser > (
  lhs: P1, rhs: P2
) -> Parse<P1.Input, ParserBuilder<P1.Input>.SkipSecond<
  P1,
  Skip<P1.Input, P2>
>> {
  Parse {
    lhs
    Skip { rhs }
  }
}

@inlinable
public func | <P1: NewParser, P2: NewParser>(
  lhs: P1, rhs: P2
) -> OneOf<P1.Input, P1.Output, OneOfBuilder<P1.Input, P1.Output>.OneOf2<
  P1,
  P2
>>
  where P1.Input == P2.Input, P1.Output == P2.Output {
  OneOf {
    lhs
    rhs
  }
}

@inlinable
public func ~ <P1: NewParser, P2: NewParser>(
  lhs: P1, rhs: P2
) -> Parse<P1.Input, ParserBuilder<P1.Input>.Take2<P1, P2>.Map<(
  P1.Output,
  P2.Output
)>>
  where P1.Input == P2.Input {
  Parse {
    lhs
    rhs
  }
}

@inlinable
public postfix func ~? <P: NewParser>(
  p: P
) -> Optionally<P.Input, P> {
  Optionally { p }
}

@inlinable
public postfix func * <P: NewParser>(
  p: P
)
  -> Many<
    P.Input,
    P,
    [P.Output],
    Always<P.Input, Void>,
    Always<P.Input, Void>,
    Void
  > {
  Many { p }
}

@inlinable
public postfix func + <P: NewParser>(
  p: P
)
  -> Many<
    P.Input,
    P,
    [P.Output],
    Always<P.Input, Void>,
    Always<P.Input, Void>,
    Void
  > {
  Many(1...) { p }
}

extension String {
  var substring: Substring {
    get { self[...] }
    set { self = String(newValue) }
  }
}

extension Array {
  var slice: ArraySlice<Element> {
    get { self[...] }
    set { self = Array(newValue) }
  }
}

extension NewParser {
  func run(_ data: Input) -> Result<Output, Error> {
    Result { try parse(data) }
  }
}
