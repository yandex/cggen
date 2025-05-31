import Darwin

import Parsing

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
  public var parseImpl: (inout Input) -> Result<Output, Error>

  public init(_ parse: @escaping (inout Input) -> Result<Output, Error>) {
    parseImpl = parse
  }

  public func parse(_ input: inout Input) throws -> Output {
    try parseImpl(&input).get()
  }
}

extension NewParser {
  public var oldParser: Parser<Input, Output> {
    .init(self)
  }
}

public struct Parser<D, T>: NewParser {
  public typealias Input = D
  public typealias Output = T

  public struct GenericError: Error {
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
  public init(_ parse: @escaping (inout D) -> Result<T, Error>) {
    newParser = AdhocParser(parse)
  }

  @inlinable
  public init(_ p: any NewParser<D, T>) {
    newParser = p
  }

  @inlinable
  public static func opt(parse: @escaping (inout D) -> T?) -> Parser<D, T> {
    .init {
      .init(optional: parse(&$0), or: GenericError($0))
    }
  }

  @inlinable
  public static func always(_ t: T) -> Parser<D, T> {
    .init(Base.always(.success(t)))
  }

  @inlinable
  public static func never() -> Parser<D, T> {
    .init(Base.always(.failure(ParseError.never)))
  }

  @inlinable
  public var optional: Parser<D?, T> {
    .init {
      guard var datum = $0 else {
        return .failure(ParseError.gotNilExpected(type: D.self))
      }
      let result = self.tempRun(&datum)
      return result
    }
  }

  @inlinable
  public func map<T1>(_ t: @escaping (T) -> T1) -> Parser<D, T1> {
    .init { self.tempRun(&$0).map(t) }
  }

  @inlinable
  public func flatMap<T1>(
    _ t: @escaping (T) -> (Parser<D, T1>)
  ) -> Parser<D, T1> {
    Parser<D, T1> { data in
      let original = data
      let res = self.tempRun(&data).flatMap { t($0).tempRun(&data) }
      res.onFailure { data = original }
      return res
    }
  }

  @inlinable
  public func flatMapResult<T1>(
    _ t: @escaping (T) -> (Result<T1, Error>)
  ) -> Parser<D, T1> {
    Parser<D, T1> { data in
      self.tempRun(&data).flatMap(t)
    }
  }

  @inlinable
  public func pullback<D1>(
    get: @escaping (D1) -> D,
    set: @escaping (inout D1, D) -> Void
  ) -> Parser<D1, T> {
    .init {
      var d = get($0)
      let result = self.tempRun(&d)
      set(&$0, d)
      return result
    }
  }

  @inlinable
  public func pullback<D1>(
    _ kp: WritableKeyPath<D1, D>
  ) -> Parser<D1, T> {
    pullback(get: kp.getter, set: kp.setter)
  }
}

extension Parser where D == T, D: RangeReplaceableCollection {
  @inlinable
  public static func identity() -> Parser<D, D> {
    .init { data in
      defer { data.removeAll(keepingCapacity: false) }
      return .success(data)
    }
  }
}

extension Parser where D: Collection, D.SubSequence == D {
  static func next(
    _ parse: @escaping (D.Element) -> Result<T, Error>
  ) -> Parser<D, T> {
    .init { data in
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

extension Parser where D == T? {
  static func unwrap() -> Parser<D, T> {
    fatalError()
  }
}

public func atIndex<D: RangeReplaceableCollection>(
  idx: D.Index
) -> Parser<D, D.Element> {
  .opt {
    $0.remove(at: idx)
  }
}

public func key<K, V>(key: K) -> Parser<[K: V], V> {
  .opt {
    $0.removeValue(forKey: key)
  }
}

@inlinable
public func maybe<D, T>(_ p: Parser<D, T>) -> Parser<D, T?> {
  .init {
    p.tempRun(&$0).map(Optional.some).flatMapError(always(.success(nil)))
  }
}

@inlinable
public func maybe<D>(_ p: Parser<D, Void>) -> Parser<D, Void> {
  .init {
    p.tempRun(&$0).flatMapError(always(.success(())))
  }
}

@inlinable
public func zeroOrMore<D, A, S>(
  _ p: some NewParser<D, A>,
  separator: some NewParser<D, S>
) -> Parser<D, [A]> {
  Many {
    p
  } separator: {
    separator
  }.oldParser
}

@inlinable
public func zeroOrMore<D, A>(
  _ p: Parser<D, A>
) -> Parser<D, [A]> {
  zeroOrMore(p, separator: Parser.always(()))
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
public func oneOrMore<D, A, S>(
  _ p: some NewParser<D, A>,
  separator: some NewParser<D, S>
) -> Parser<D, [A]> {
  zeroOrMore(p, separator: separator).flatMapResult {
    $0.count == 0 ? .failure(ParseError.atLeastOneExpected) : .success($0)
  }
}

@inlinable
public func oneOrMore<D, A>(
  _ p: some NewParser<D, A>
) -> Parser<D, [A]> {
  oneOrMore(p, separator: Parser.always(()))
}

@inlinable
public func consume<C: Collection>(
  element: C.Element
) -> Parser<C, Void> where C.SubSequence == C, C.Element: Equatable {
  .opt {
    guard let first = $0.first, element == first else {
      return nil
    }
    $0.removeFirst()
    return ()
  }
}

@inlinable
public func consume<C: Collection>(
  while predicate: @escaping (C.Element) -> Bool
) -> Parser<C, C.SubSequence> where C.SubSequence == C {
  .opt {
    let result = $0.prefix(while: predicate)
    $0.removeFirst(result.count)
    return result
  }
}

@inlinable
public func skipZeroOrMore<C: Collection>(
  chars: Set<C.Element>
) -> Parser<C, Void> where C.SubSequence == C {
  .init {
    let prefix = $0.prefix(while: chars.contains)
    $0.removeFirst(prefix.count)
    return .success(())
  }
}

@inlinable
public func skipZeroOrMore<C: Collection>(
  char: C.Element
) -> Parser<C, Void> where C.SubSequence == C, C.Element: Hashable {
  skipZeroOrMore(chars: [char])
}

@inlinable
public func skipOneOrMore<C: Collection>(
  chars: Set<C.Element>
) -> Parser<C, Void> where C.SubSequence == C {
  .opt {
    let prefix = $0.prefix(while: chars.contains)
    guard prefix.count == 0 else {
      return nil
    }
    $0.removeFirst(prefix.count)
    return ()
  }
}

@inlinable
public func skipOneOrMore<C: Collection>(
  char: C.Element
) -> Parser<C, Void> where C.SubSequence == C, C.Element: Hashable {
  skipOneOrMore(chars: [char])
}

@inlinable
public func oneOf<D, A>(
  _ ps: [any NewParser<D, A>]
) -> some NewParser<D, A> {
  Parser.opt { str in
    for p in ps {
      if case let .success(match) = p.oldParser.tempRun(&str) {
        return match
      }
    }
    return nil
  }
}

@inlinable
public func oneOf<D, A>(
  _ ps: any NewParser<D, A>...
) -> some NewParser<D, A> {
  oneOf(ps)
}

@inlinable
public func longestOneOf<D: Collection, A>(
  _ ps: [any NewParser<D, A>]
) -> Parser<D, A> {
  .opt { str in
    let initial = str
    let initialLen = str.count
    var maxlen: Int = -1
    var resultData = str
    var result: A?
    for p in ps {
      str = initial
      if case let .success(match) = Result(catching: { try p.parse(&str) }),
         initialLen - str.count > maxlen {
        maxlen = initialLen - str.count
        result = match
        resultData = str
      }
    }
    str = resultData
    return result
  }
}

@inlinable
public func read<D: Collection>(
  exactly n: Int
) -> Parser<D, D.SubSequence> where D.SubSequence == D {
  .opt { data in
    let prefix = data.prefix(n)
    guard prefix.count == n else { return nil }
    data.removeFirst(n)
    return prefix
  }
}

@inlinable
public func readOne<D: Collection>(
) -> Parser<D, D.Element> where D.SubSequence == D {
  .opt { $0.popFirst() }
}

@inlinable
public func oneOf<D: Collection, T: CaseIterable & RawRepresentable>(
  parserFactory: @escaping (T.RawValue) -> Parser<D, Void>,
  _: T.Type = T.self
) -> some NewParser<D, T> {
  oneOf(T.allCases.map {
    parserFactory($0.rawValue).map(always($0)).oldParser
  })
}

@inlinable
public func longestOneOf<D: Collection, T: CaseIterable & RawRepresentable>(
  parserFactory: @escaping (T.RawValue) -> some NewParser<D, Void>,
  _: T.Type = T.self
) -> some NewParser<D, T> {
  longestOneOf(
    T.allCases.map { case_ in
      parserFactory(case_.rawValue).map { always(case_)($0) }
        .oldParser
    }
  )
}

@inlinable
public func endof<D: Collection>(_: D.Type = D.self) -> Parser<D, Void> {
  .init {
    $0.count == 0 ?
      .success(()) :
      .failure(ParseError.parsingNotComplete(left: "\($0)"))
  }
}

@inlinable
public func ~>> <D, T, T1>(
  lhs: some NewParser<D, T1>,
  rhs: some NewParser<D, T>
) -> Parser<D, T> {
  Parse {
    lhs
    rhs
  }.map { $0.1 }.oldParser
}

@inlinable
public func <<~< D, T, T1 > (
  lhs: some NewParser<D, T>, rhs: some NewParser<D, T1>
) -> Parser<D, T> {
  Parse {
    lhs
    rhs
  }.map { $0.0 }.oldParser
}

@inlinable
public func | <D, T>(
  lhs: some NewParser<D, T>,
  rhs: some NewParser<D, T>
) -> Parser<D, T> {
  OneOf {
    lhs
    rhs
  }.oldParser
}

@inlinable
public func ~ <D, T1, T2>(
  lhs: some NewParser<D, T1>, rhs: some NewParser<D, T2>
) -> Parser<D, (T1, T2)> {
  Parse {
    lhs
    rhs
  }.oldParser
}

@inlinable
public postfix func ~? <D, T>(p: some NewParser<D, T>) -> Parser<D, T?> {
  Optionally { p }.oldParser
}

@inlinable
public postfix func * <D, T>(p: some NewParser<D, T>) -> Parser<D, [T]> {
  Many { p }.oldParser
}

@inlinable
public postfix func + <D, T>(
  p: some NewParser<D, T>
) -> some NewParser<D, [T]> {
  Many(1...) { p }
}

@inlinable
public func oneOf<T: CaseIterable & RawRepresentable>(
  _: T.Type = T.self
) -> some NewParser<Substring, T> where T.RawValue == String {
  longestOneOf(parserFactory: { $0 })
}

extension String {
  var substring: Substring {
    get { self[...] }
    set { self = String(newValue) }
  }
}
