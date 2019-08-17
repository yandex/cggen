import Base
import XCTest

class PareserTests: XCTestCase {
  typealias Parser<T> = Base.Parser<Substring, T>

  private let int: Parser<Int> = Base.int()
  private let double: Parser<Double> = Base.double()

  func testDoubleParser() {
    double.test("123", expected: (123, ""))
    double.test("12.3", expected: (12.3, ""))
    double.test("123hello", expected: (123, "hello"))
    double.test("12.3 hello", expected: (12.3, " hello"))
    double.test("2.9e8", expected: (2.9e8, ""))
    double.test("2.9e-8", expected: (2.9e-8, ""))
    double.test("-2.9e-8", expected: (-2.9e-8, ""))
    double.test("abc", expected: (nil, "abc"))
  }

  func testIntParser() {
    int.test("123", expected: (123, ""))
    int.test("45.6", expected: (45, ".6"))
    int.test("7890 hello", expected: (7890, " hello"))
    int.test("-357", expected: (-357, ""))
    int.test("abc", expected: (nil, "abc"))
  }

  func testConsumeStringParser() {
    let p: Parser<Void> = "foo"
    p.test("foo")
    p.test("foo___", expected: ((), "___"))
    p.test("___foo", expected: (nil, "___foo"))
  }

  func testConsumeCharParser() {
    let p: Parser<Void> = consume(element: "f")
    p.test("f")
    p.test("fff", expected: ((), "ff"))
    p.test("_f_", expected: (nil, "_f_"))
  }

  func testMap() {
    let p: Parser<String> = int.map { "_\($0 + 1)_" }
    p.test("42", expected: ("_43_", ""))
    p.test("15_", expected: ("_16_", "_"))
  }

  func testZip() {
    let p: Parser<Int> = zip(int, "_").map { $0.0 }
    p.test("12_", expected: (12, ""))
    p.test("34__", expected: (34, "_"))
    p.test("56", expected: (nil, "56"))
    p.test("_56", expected: (nil, "_56"))
  }

  func testZeroOrMore() {
    let p: Parser<[Int]> = zip(int, "_").map { $0.0 }*
    p.test("12_13_14_", expected: ([12, 13, 14], ""))
    p.test("12_13_14", expected: ([12, 13], "14"))
    p.test("foobar", expected: ([], "foobar"))
  }

  func testOneOrMore() {
    let p: Parser<[Int]> = zip(int, "_").map { $0.0 }+
    p.test("12_13_14_", expected: ([12, 13, 14], ""))
    p.test("12_13_14", expected: ([12, 13], "14"))
    p.test("foobar", expected: (nil, "foobar"))
  }

  func testMayBe() {
    let p: Parser<Int?> = zip(int, "_").map { $0.0 }~?
    p.test("123_", expected: (123, ""))
    p.test("_", expected: (.some(nil), "_"))
  }

  func testIntoParser() {
    let p: Parser<Int> = "{" ~>> " "* ~>> int <<~ " "* <<~ "}"
    p.test("{123}", expected: (123, ""))
    p.test("{123}}", expected: (123, "}"))
    p.test("{  45 }", expected: (45, ""))
  }

  func testCombineParser() {
    struct Pair<T: Equatable, U: Equatable>: Equatable {
      var t: T
      var u: U
    }
    let pair: Parser<(Int, Double)> =
      "{" ~>> int <<~ "}" ~ "{" ~>> double <<~ "}"
    let p: Parser<Pair<Int, Double>> = pair.map { .init(t: $0.0, u: $0.1) }
    p.test("{1}{2.3}{2}", expected: (.init(t: 1, u: 2.3), "{2}"))
  }
}

extension Parser where D == Substring, T: Equatable {
  func test(
    _ data: String,
    expected: (result: T?, rest: String),
    file: StaticString = #file, line: UInt = #line
  ) {
    var data = Substring(data)
    XCTAssertEqual(expected.result, run(&data), file: file, line: line)
    XCTAssertEqual(expected.rest, String(data), file: file, line: line)
  }
}

extension Parser where D == Substring, T == Void {
  func test(
    _ data: String,
    expected: (result: Void?, rest: String) = ((), ""),
    file: StaticString = #file, line: UInt = #line
  ) {
    var data = Substring(data)
    let result: Void? = run(&data)
    if expected.result == nil {
      XCTAssertNil(result, file: file, line: line)
    } else {
      XCTAssertNotNil(result, file: file, line: line)
    }
    XCTAssertEqual(String(data), expected.rest, file: file, line: line)
  }
}
