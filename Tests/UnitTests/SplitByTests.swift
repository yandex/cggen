import Base
import XCTest

class SplitByTests: XCTestCase {
  func testSplitBy() {
    XCTAssertEqual(
      Array([0, 1, 2, 3].splitBy(subSize: 2)),
      [[0, 1], [2, 3]]
    )
  }
}
