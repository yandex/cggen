import Testing

import Base
import Parsing

@Suite struct PareserTests {
  typealias Parser<T> = Base.OldParser<Substring, T>
  typealias NewParser<T> = Base.NewParser<Substring, T>

  private let int = Parse(input: Substring.self) {
    Int.parser()
  }

  private let double = Parse(input: Substring.self) {
    Double.parser()
  }

  @Test func testDoubleParser() {
    double.test("123", expected: (123, ""))
    double.test("12.3", expected: (12.3, ""))
    double.test("123hello", expected: (123, "hello"))
    double.test("12.3 hello", expected: (12.3, " hello"))
    double.test("2.9e8", expected: (2.9e8, ""))
    double.test("2.9e-8", expected: (2.9e-8, ""))
    double.test("-2.9e-8", expected: (-2.9e-8, ""))
    double.test("-2.9-8", expected: (-2.9, "-8"))
    double.test(" -2.0", expected: (nil, " -2.0"))
    double.test(".78", expected: (0.78, ""))
    double.test(".1.78", expected: (0.1, ".78"))
    double.test(" ", expected: (nil, " "))
    double.test("abc", expected: (nil, "abc"))
  }

  @Test func testIntParser() {
    int.test("123", expected: (123, ""))
    int.test("45.6", expected: (45, ".6"))
    int.test("7890 hello", expected: (7890, " hello"))
    int.test("-357", expected: (-357, ""))
    int.test("-45-34", expected: (-45, "-34"))
    int.test("  2", expected: (nil, "  2"))
    int.test(" ", expected: (nil, " "))
    int.test("abc", expected: (nil, "abc"))
  }

  @Test func testConsumeStringParser() {
    let p: some NewParser<Void> = "foo"
    p.test("foo")
    p.test("foo___", expected: ((), "___"))
    p.test("___foo", expected: (nil, "___foo"))
  }

  @Test func testConsumeCharParser() {
    let p: some NewParser<Void> = "f".map { _ in () }
    p.test("f")
    p.test("fff", expected: ((), "ff"))
    p.test("_f_", expected: (nil, "_f_"))
  }

  @Test func testMap() {
    let p: some NewParser<String> = int.map { "_\($0 + 1)_" }
    p.test("42", expected: ("_43_", ""))
    p.test("15_", expected: ("_16_", "_"))
  }

  @Test func testZip() {
    let p: Parser<Int> = zip(int, "_", with: { int, _ in int })
    p.test("12_", expected: (12, ""))
    p.test("34__", expected: (34, "_"))
    p.test("56", expected: (nil, ""))
    p.test("_56", expected: (nil, "_56"))
  }

  @Test func testZeroOrMore() {
    let p: some NewParser<[Int]> = (int <<~ "_")*
    p.test("12_13_14_", expected: ([12, 13, 14], ""))
    p.test("12_13_14", expected: ([12, 13], "14"))
    p.test("foobar", expected: ([], "foobar"))
  }

  @Test func testZeroOrMoreWithSeparator() {
    let p: some NewParser<[Int]> = Many { int } separator: { " " }
    p.test("1 2 3", expected: ([1, 2, 3], ""))
    p.test("12 13 14 ", expected: ([12, 13, 14], " "))
    p.test("12 13 foo", expected: ([12, 13], " foo"))
    p.test("-12-13", expected: ([-12], "-13"))
  }

  @Test func testOneOrMore() {
    let p: some NewParser<[Int]> = (int <<~ "_")+
    p.test("12_13_14_", expected: ([12, 13, 14], ""))
    p.test("12_13_14", expected: ([12, 13], "14"))
    p.test("foobar", expected: (nil, "foobar"))
  }

  @Test func testMayBe() {
    let p: some NewParser<Int?> = (int <<~ "_")~?
    p.test("123_", expected: (123, ""))
    p.test("_", expected: (.some(nil), "_"))
  }

  @Test func testIntoParser() {
    let p: some NewParser<Int> = "{" ~>> " "* ~>> int <<~ " "* <<~ "}"
    p.test("{123}", expected: (123, ""))
    p.test("{123}}", expected: (123, "}"))
    p.test("{  45 }", expected: (45, ""))
  }

  @Test func testCombineParser() {
    struct Pair<T: Equatable, U: Equatable>: Equatable {
      var t: T
      var u: U
    }
    let pair: some NewParser<(Int, Double)> =
      "{" ~>> int <<~ "}" ~ "{" ~>> double <<~ "}"
    let p: some NewParser<Pair<Int, Double>> = pair
      .map { .init(t: $0.0, u: $0.1) }
    p.test("{1}{2.3}{2}", expected: (.init(t: 1, u: 2.3), "{2}"))
  }

  @Test func testOneOfCaseIterableParser() {
    enum InnerPlanets: String, CaseIterable {
      case mercury, venus, earth, mars
    }
    let p: some NewParser<InnerPlanets> = InnerPlanets.parser()
    p.test("mars", expected: (.mars, ""))
    p.test("earthmars", expected: (.earth, "mars"))
    p.test("marsearth", expected: (.mars, "earth"))
  }

  @Test func testOneOfCaseIterable_OneIsPrefixToAnother() {
    enum Colors: String, CaseIterable {
      case aqua, aquamarine
    }
    let p: some NewParser<Colors> = Colors.parser()
    p.test("aqua", expected: (.aqua, ""))
    p.test("aquamarine", expected: (.aquamarine, ""))
  }

  @Test func testIdentityParser() {
    let p: Parser<Substring> = .identity()
    p.test("foo bar", expected: ("foo bar", ""))
  }

  @Test func testAlwaysParser() {
    let p: Parser<Int> = .always(156)
    p.test("hello", expected: (156, "hello"))
  }

  @Test func testNeverParser() {
    let p: Parser<Int> = .never()
    p.test("1", expected: (nil, "1"))
  }

  @Test func testConsumeWhile() {
    let p: some NewParser<Substring> = Prefix(while: { $0 != "_" })
    p.test("123_", expected: ("123", "_"))
  }
}

extension NewParser where Input == Substring, Output: Equatable {
  func test(
    _ data: String,
    expected: (result: Output?, rest: String)
  ) {
    var dataToParse = Substring(data)
    let res = Result { try parse(&dataToParse) }
    #expect(expected.result == res.value)
    #expect(expected.rest == String(dataToParse))
  }
}

extension NewParser where Input == Substring, Output == Void {
  func test(
    _ data: String,
    expected: (result: Void?, rest: String) = ((), "")
  ) {
    var data = Substring(data)
    let result: Void? = try? parse(&data)
    if expected.result == nil {
      #expect(result == nil)
    } else {
      #expect(result != nil)
    }
    #expect(String(data) == expected.rest)
  }
}
