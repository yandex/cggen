import Base
import XCTest

class SplitByTests: XCTestCase {
  func testSplitBy() {
    XCTAssertEqual(
      Array([0, 1, 2, 3].splitBy(subSize: 2)),
      [[0, 1], [2, 3]]
    )
  }

  func testSplitSubscript() {
    let xs = [0, 1, 2, 3, 4, 5].splitBy(subSize: 3)
    XCTAssertEqual(xs[0].startIndex, 0)
    XCTAssertEqual(xs[0].endIndex, 3)
    XCTAssertEqual(xs[1].startIndex, 3)
    XCTAssertEqual(xs[1].endIndex, 6)
  }
}
