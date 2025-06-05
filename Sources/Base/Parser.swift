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

struct DicitionaryKey<Key: Hashable & Sendable, Value>: Parser, Sendable {
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
public func ~>> <P1: Parser, P2: Parser>(
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
public func <<~< P1: Parser, P2: Parser > (
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
public func | <P1: Parser, P2: Parser>(
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
public func ~ <P1: Parser, P2: Parser>(
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
public postfix func ~? <P: Parser>(
  p: P
) -> Optionally<P.Input, P> {
  Optionally { p }
}

@inlinable
public postfix func * <P: Parser>(
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
public postfix func + <P: Parser>(
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

extension Parser {
  func run(_ data: Input) -> Result<Output, Error> {
    Result { try parse(data) }
  }
}

struct OptionalInput<P: Parser>: Parser {
  var parser: P

  init(_ parser: P) {
    self.parser = parser
  }

  func parse(_ input: inout P.Input?) throws -> P.Output {
    guard var nonil = input else {
      throw ParseError.gotNilExpected(type: P.Input.self)
    }
    defer { input = nonil }
    return try parser.parse(&nonil)
  }
}
