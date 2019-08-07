import XCTest
import Base

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
}
