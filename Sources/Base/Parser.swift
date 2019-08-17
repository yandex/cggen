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

infix operator ~>>: StreamRight
infix operator <<~: StreamLeft
infix operator ~: StreamAddition
postfix operator *
postfix operator +
postfix operator ~?

public struct Parser<D, T> {
  public struct GenericError: Error {
    public var text: D
    public var type: T.Type

    var localizedDescription: String {
      return "Couldn't parse \(type) from <\(text)>"
    }

    @inlinable
    public init(_ text: D) {
      self.text = text
      type = T.self
    }
  }

  public typealias Error = Swift.Error

  public var parse: (inout D) -> Result<T, Error>

  @inlinable
  public func run(_ data: inout D) -> T? {
    return parse(&data).value
  }

  @inlinable
  public init(parse: @escaping (inout D) -> Result<T, Error>) {
    self.parse = parse
  }

  @inlinable
  public static func opt(parse: @escaping (inout D) -> T?) -> Parser<D, T> {
    return .init {
      .init(optional: parse(&$0), or: GenericError($0))
    }
  }

  @inlinable
  public func map<T1>(_ t: @escaping (T) -> T1) -> Parser<D, T1> {
    return .init { self.parse(&$0).map(t) }
  }

  @inlinable
  public func flatMap<T1>(_ t: @escaping (T) -> (Parser<D, T1>)) -> Parser<D, T1> {
    return Parser<D, T1> { data in
      let original = data
      let res = self.parse(&data).flatMap { t($0).parse(&data) }
      switch res {
      case .failure:
        data = original
      case .success:
        break
      }
      return res
    }
  }
}

@inlinable
public func zip<A1, A2, D>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>
) -> Parser<D, (A1, A2)> {
  return p1.flatMap { a in p2.map { b in (a, b) } }
}

@inlinable
public func zip<A1, A2, A3, D>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>
) -> Parser<D, (A1, A2, A3)> {
  return zip(p1, zip(p2, p3)).map { ($0.0, $0.1.0, $0.1.1) }
}

@inlinable
public func zip<A1, A2, A3, A4, D>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>
) -> Parser<D, (A1, A2, A3, A4)> {
  return zip(p1, zip(p2, p3, p4)).map { ($0.0, $0.1.0, $0.1.1, $0.1.2) }
}

@inlinable
public func maybe<D, T>(_ p: Parser<D, T>) -> Parser<D, T?> {
  return .init {
    p.parse(&$0).map(Optional.some).flatMapError { _ in .success(nil) }
  }
}

@inlinable
public func maybe<D>(_ p: Parser<D, Void>) -> Parser<D, Void> {
  return .init {
    p.parse(&$0).flatMapError { _ in .success(()) }
  }
}

@inlinable
public func zeroOrMore<D, A>(_ p: Parser<D, A>) -> Parser<D, [A]> {
  return .init {
    var matches: [A] = []
    while case let .success(match) = p.parse(&$0) {
      matches.append(match)
    }
    return .success(matches)
  }
}

@inlinable
public func oneOrMore<D, A>(_ p: Parser<D, A>) -> Parser<D, [A]> {
  return .opt {
    var matches: [A] = []
    while case let .success(match) = p.parse(&$0) {
      matches.append(match)
    }
    guard matches.count > 0 else {
      return nil
    }
    return matches
  }
}

@inlinable
public func consume<C: Collection>(
  element: C.Element
) -> Parser<C, Void> where C.SubSequence == C, C.Element: Equatable {
  return .opt {
    guard let first = $0.first, element == first else {
      return nil
    }
    $0.removeFirst()
    return ()
  }
}

@inlinable
public func skipZeroOrMore<C: Collection>(
  chars: Set<C.Element>
) -> Parser<C, Void> where C.SubSequence == C {
  return .init {
    let prefix = $0.prefix(while: chars.contains)
    $0.removeFirst(prefix.count)
    return .success(())
  }
}

@inlinable
public func skipZeroOrMore<C: Collection>(
  char: C.Element
) -> Parser<C, Void> where C.SubSequence == C, C.Element: Hashable {
  return skipZeroOrMore(chars: [char])
}

public enum ParseError: Error {
  case consume(expected: String, got: String)
  case never
  case couldntConvertStringTo(type: String)
  case parsingNotComplete(last: String)
}

@inlinable
public func skipOneOrMore<C: Collection>(
  chars: Set<C.Element>
) -> Parser<C, Void> where C.SubSequence == C {
  return .opt {
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
  return skipOneOrMore(chars: [char])
}

@inlinable
public func oneOf<D, A>(_ ps: [Parser<D, A>]) -> Parser<D, A> {
  return .opt { str in
    for p in ps {
      if case let .success(match) = p.parse(&str) {
        return match
      }
    }
    return nil
  }
}

@inlinable
public func never<D, V>() -> Parser<D, V> {
  return .init { _ in .failure(ParseError.never) }
}

@inlinable
public func ~>> <D, T, T1>(
  lhs: Parser<D, T1>, rhs: Parser<D, T>
) -> Parser<D, T> {
  return zip(lhs, rhs).map { $0.1 }
}

@inlinable
public func <<~< D, T, T1 > (
  lhs: Parser<D, T>, rhs: Parser<D, T1>
) -> Parser<D, T> {
  return zip(lhs, rhs).map { $0.0 }
}

@inlinable
public func | <D, T>(lhs: Parser<D, T>, rhs: Parser<D, T>) -> Parser<D, T> {
  return oneOf([lhs, rhs])
}

@inlinable
public func ~ <D, T1, T2>(
  lhs: Parser<D, T1>, rhs: Parser<D, T2>
) -> Parser<D, (T1, T2)> {
  return zip(lhs, rhs)
}

@inlinable
public postfix func ~? <D, T>(p: Parser<D, T>) -> Parser<D, T?> {
  return maybe(p)
}

@inlinable
public postfix func * <D, T>(p: Parser<D, T>) -> Parser<D, [T]> {
  return zeroOrMore(p)
}

@inlinable
public postfix func + <D, T>(p: Parser<D, T>) -> Parser<D, [T]> {
  return oneOrMore(p)
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

extension Parser where D: StringProtocol {
  @inlinable
  public func full(_ s: String) -> Result<T, Error> {
    guard var data = D(s) else {
      return .failure(ParseError.couldntConvertStringTo(type: "\(D.self)"))
    }
    let result = parse(&data)
    guard data.count == 0 else {
      return .failure(ParseError.parsingNotComplete(last: data.description))
    }
    return result
  }
}

@inlinable
public func consume<S: StringProtocol>(
  _ s: String
) -> Parser<S, Void> where S.SubSequence == S {
  return .init { (data) -> Result<Void, Error> in
    guard data.hasPrefix(s) else {
      return .failure(
        ParseError.consume(expected: s, got: data.prefix(s.count).description)
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
  return .opt {
    let (res, len) = $0.withCString { (cstr) -> (Int, Int) in
      var endPointer: UnsafeMutablePointer<Int8>?
      let res = strtol(cstr, &endPointer, radix)
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

@inlinable
public func double<S: StringProtocol>(
) -> Parser<S, Double> where S.SubSequence == S {
  return .opt {
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
