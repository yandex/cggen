import Darwin

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

public struct Parser<D, T> {
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

  public var parse: (inout D) -> Result<T, Error>

  @inlinable
  public func run(_ data: inout D) -> T? {
    parse(&data).value
  }

  @inlinable
  public func run(_ data: D) -> Result<T, Error> {
    var copy = data
    return parse(&copy)
  }

  @inlinable
  public init(_ parse: @escaping (inout D) -> Result<T, Error>) {
    self.parse = parse
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
      let result = self.parse(&datum)
      return result
    }
  }

  @inlinable
  public func map<T1>(_ t: @escaping (T) -> T1) -> Parser<D, T1> {
    .init { self.parse(&$0).map(t) }
  }

  @inlinable
  public func flatMap<T1>(
    _ t: @escaping (T) -> (Parser<D, T1>)
  ) -> Parser<D, T1> {
    Parser<D, T1> { data in
      let original = data
      let res = self.parse(&data).flatMap { t($0).parse(&data) }
      res.onFailure { data = original }
      return res
    }
  }

  @inlinable
  public func flatMapResult<T1>(
    _ t: @escaping (T) -> (Result<T1, Error>)
  ) -> Parser<D, T1> {
    Parser<D, T1> { data in
      self.parse(&data).flatMap(t)
    }
  }

  @inlinable
  public func pullback<D1>(
    get: @escaping (D1) -> D,
    set: @escaping (inout D1, D) -> Void
  ) -> Parser<D1, T> {
    return .init {
      var d = get($0)
      let result = self.parse(&d)
      set(&$0, d)
      return result
    }
  }

  @inlinable
  public func pullback<D1>(
    _ kp: WritableKeyPath<D1, D>
  ) -> Parser<D1, T> {
    return pullback(get: ^kp, set: ^kp)
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

public func atIndex<D: RangeReplaceableCollection>(idx: D.Index) -> Parser<D, D.Element> {
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
    p.parse(&$0).map(Optional.some).flatMapError(always(.success(nil)))
  }
}

@inlinable
public func maybe<D>(_ p: Parser<D, Void>) -> Parser<D, Void> {
  .init {
    p.parse(&$0).flatMapError(always(.success(())))
  }
}

@inlinable
public func zeroOrMore<D, A, S>(
  _ p: Parser<D, A>,
  separator: Parser<D, S>
) -> Parser<D, [A]> {
  .init {
    var matches: [A] = []
    var lastBeforeSeparator = $0
    var firstOrHasSeparatorBefore = true
    while case let .success(match) = p.parse(&$0), firstOrHasSeparatorBefore {
      matches.append(match)
      lastBeforeSeparator = $0
      firstOrHasSeparatorBefore = separator.parse(&$0).isSucceed
    }
    $0 = lastBeforeSeparator
    return .success(matches)
  }
}

@inlinable
public func zeroOrMore<D, A>(
  _ p: Parser<D, A>
) -> Parser<D, [A]> {
  zeroOrMore(p, separator: .always(()))
}

public enum ParseError: Error {
  case atLeastOneExpected
  case consume(expected: String, got: String)
  case never
  case couldntConvertStringTo(type: String)
  case parsingNotComplete(last: String)
  case gotNilExpected(String)

  @inlinable
  public static func gotNilExpected<T>(type: T.Type) -> ParseError {
    return .gotNilExpected(String(describing: type))
  }
}

@inlinable
public func oneOrMore<D, A, S>(
  _ p: Parser<D, A>,
  separator: Parser<D, S>
) -> Parser<D, [A]> {
  zeroOrMore(p, separator: separator).flatMapResult {
    $0.count == 0 ? .failure(ParseError.atLeastOneExpected) : .success($0)
  }
}

@inlinable
public func oneOrMore<D, A>(
  _ p: Parser<D, A>
) -> Parser<D, [A]> {
  oneOrMore(p, separator: .always(()))
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
public func oneOf<D, A>(_ ps: [Parser<D, A>]) -> Parser<D, A> {
  .opt { str in
    for p in ps {
      if case let .success(match) = p.parse(&str) {
        return match
      }
    }
    return nil
  }
}

@inlinable
public func longestOneOf<D: Collection, A>(_ ps: [Parser<D, A>]) -> Parser<D, A> {
  .opt { str in
    let initial = str
    let initialLen = str.count
    var maxlen: Int = -1
    var resultData = str
    var result: A?
    for p in ps {
      str = initial
      if case let .success(match) = p.parse(&str), initialLen - str.count > maxlen {
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
) -> Parser<D, T> {
  oneOf(T.allCases.map { parserFactory($0.rawValue).map(always($0)) })
}

@inlinable
public func longestOneOf<D: Collection, T: CaseIterable & RawRepresentable>(
  parserFactory: @escaping (T.RawValue) -> Parser<D, Void>,
  _: T.Type = T.self
) -> Parser<D, T> {
  longestOneOf(
    T.allCases.map { parserFactory($0.rawValue).map(always($0)) }
  )
}

@inlinable
public func endof<D: Collection>(_: D.Type = D.self) -> Parser<D, Void> {
  .init {
    $0.count == 0 ?
      .success(()) :
      .failure(ParseError.parsingNotComplete(last: "\($0)"))
  }
}

@inlinable
public func ~>> <D, T, T1>(
  lhs: Parser<D, T1>, rhs: Parser<D, T>
) -> Parser<D, T> {
  zip(lhs, rhs) { $1 }
}

@inlinable
public func <<~< D, T, T1 > (
  lhs: Parser<D, T>, rhs: Parser<D, T1>
) -> Parser<D, T> {
  zip(lhs, rhs) { lhs, _ in lhs }
}

@inlinable
public func | <D, T>(lhs: Parser<D, T>, rhs: Parser<D, T>) -> Parser<D, T> {
  oneOf([lhs, rhs])
}

@inlinable
public func ~ <D, T1, T2>(
  lhs: Parser<D, T1>, rhs: Parser<D, T2>
) -> Parser<D, (T1, T2)> {
  zip(lhs, rhs, with: identity)
}

@inlinable
public postfix func ~? <D, T>(p: Parser<D, T>) -> Parser<D, T?> {
  maybe(p)
}

@inlinable
public postfix func * <D, T>(p: Parser<D, T>) -> Parser<D, [T]> {
  zeroOrMore(p)
}

@inlinable
public postfix func + <D, T>(p: Parser<D, T>) -> Parser<D, [T]> {
  oneOrMore(p)
}

// String parsers

extension Parser:
  ExpressibleByStringLiteral,
  ExpressibleByExtendedGraphemeClusterLiteral,
  ExpressibleByUnicodeScalarLiteral
  where D: StringProtocol, T == Void, D.SubSequence == D {
  @inlinable
  public init(stringLiteral value: StaticString) {
    let s = value.description
    self.init { (data) -> Result<Void, Error> in
      guard data.hasPrefix(s) else {
        return .failure(ParseError.consume(
          expected: value.description,
          got: data.prefix(s.count).description
        ))
      }
      data.removeFirst(s.count)
      return .success(())
    }
  }

  @inlinable
  public init(extendedGraphemeClusterLiteral value: StaticString) {
    self.init(stringLiteral: value)
  }

  @inlinable
  public init(unicodeScalarLiteral value: StaticString) {
    self.init(stringLiteral: value)
  }
}

extension Parser where D == Substring {
  @inlinable
  public func whole(_ s: String) -> Result<T, Error> {
    var copy = D(s)
    return (self <<~ endof()).parse(&copy)
  }
}

@inlinable
public func oneOf<D: StringProtocol, T: CaseIterable & RawRepresentable>(
  _: T.Type = T.self
) -> Parser<D, T>
  where T.RawValue: StringProtocol, D.SubSequence == D {
  longestOneOf(parserFactory: consume(_:))
}

@inlinable
public func consume<D: StringProtocol, S: StringProtocol>(
  _ s: S
) -> Parser<D, Void> where D.SubSequence == D {
  .init { (data) -> Result<Void, Error> in
    guard data.hasPrefix(s) else {
      return .failure(
        ParseError.consume(expected: String(s), got: data.prefix(s.count).description)
      )
    }
    data.removeFirst(s.count)
    return .success(())
  }
}

@inlinable
public func int<S: StringProtocol>(
  from _: S.Type = S.self,
  radix: Int32 = 10
) -> Parser<S, Int> where S.SubSequence == S {
  .opt {
    // Fail on any leading whitespace, as `strtol` skips it.
    guard let first = $0.first, !first.isWhitespace else { return nil }
    let (res, len) = $0.withCString { (cstr) -> (Int, Int) in
      var endPointer: UnsafeMutablePointer<Int8>?
      let res = strtol(cstr, &endPointer, radix)
      guard let intEndPointee = endPointer else { return (0, 0) }
      let len = cstr.distance(to: intEndPointee)
      return (res, len)
    }
    guard len > 0 else {
      return nil
    }
    $0.removeFirst(len)
    return res
  }
}

@inlinable
public func double<S: StringProtocol>(
) -> Parser<S, Double> where S.SubSequence == S {
  .opt {
    // Fail on any leading whitespace, as `strtod` skips it.
    guard let first = $0.first, !first.isWhitespace else { return nil }
    let (res, len) = $0.withCString { (cstr) -> (Double, Int) in
      var endPointer: UnsafeMutablePointer<Int8>?
      let res = strtod(cstr, &endPointer)
      guard let doubleEndPointee = endPointer else { return (0, 0) }
      let len = cstr.distance(to: doubleEndPointee)
      return (res, len)
    }
    guard len > 0 else {
      return nil
    }
    $0.removeFirst(len)
    return res
  }
}
