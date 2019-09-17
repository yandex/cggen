import Base
import XCTest

class BaseTests: XCTestCase {
  func testConcurrentMap() {
    XCTAssertEqual((0..<100).concurrentMap { $0 + 1 }, Array(1..<101))
    XCTAssertEqual(Array(0..<100).concurrentMap { $0 + 1 }, Array(1..<101))
  }

  func testThrowingConcurrentmap() throws {
    struct TestError: Error, Equatable {}
    do {
      _ = try Array(0..<100).concurrentMap {
        guard $0 != 42 else { throw TestError() }
        return $0 + 1
      } as [Int]
      XCTAssert(false)
    } catch let error as TestError {
      XCTAssertEqual(error, TestError())
    }
  }

  func testZip() {
    checkZip(zip(Int?.none, Int?.none), nil)
    checkZip(zip(42, Int?.none), nil)
    checkZip(zip(Int?.none, 42), nil)
    checkZip(zip(12, 42), (12, 42))
  }

  func testZipLongest() {
    checkZip(zipLongest(42, "42", fillFirst: 0, fillSecond: ""), (42, "42"))
    checkZip(zipLongest(nil, "42", fillFirst: 0, fillSecond: ""), (0, "42"))
    checkZip(zipLongest(42, nil, fillFirst: 0, fillSecond: ""), (42, ""))
    checkZip(zipLongest(nil, nil, fillFirst: 0, fillSecond: ""), nil)

    func failing() -> Int {
      XCTFail()
      return -1
    }
    checkZip(
      zipLongest(42, 12, fillFirst: failing(), fillSecond: failing()),
      (42, 12)
    )
    checkZip(zipLongest(nil, 42, fillFirst: 0, fillSecond: failing()), (0, 42))
    checkZip(zipLongest(42, nil, fillFirst: failing(), fillSecond: 0), (42, 0))
  }
}

private func checkZip<T: Equatable, U: Equatable>(_ lhs: (T, U)?, _ rhs: (T, U)?) {
  XCTAssertEqual(lhs?.0, rhs?.0)
  XCTAssertEqual(lhs?.1, rhs?.1)
}
