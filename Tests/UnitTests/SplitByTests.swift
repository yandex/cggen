import Testing

import CGGenCore

@Suite struct SplitByTests {
  @Test func testSplitBy() {
    #expect(
      Array([0, 1, 2, 3].splitBy(subSize: 2)) ==
        [[0, 1], [2, 3]]
    )
  }

  @Test func splitSubscript() {
    let xs = [0, 1, 2, 3, 4, 5].splitBy(subSize: 3)
    #expect(xs[0].startIndex == 0)
    #expect(xs[0].endIndex == 3)
    #expect(xs[1].startIndex == 3)
    #expect(xs[1].endIndex == 6)
  }
}
