import Testing

import CGGenCore

@Suite struct BaseTests {
  @Test func testZip() {
    checkZip(zip(Int?.none, Int?.none), nil)
    checkZip(zip(42, Int?.none), nil)
    checkZip(zip(Int?.none, 42), nil)
    checkZip(zip(12, 42), (12, 42))
  }

  @Test func testZipLongest() {
    checkZip(zipLongest(42, "42", fillFirst: 0, fillSecond: ""), (42, "42"))
    checkZip(zipLongest(nil, "42", fillFirst: 0, fillSecond: ""), (0, "42"))
    checkZip(zipLongest(42, nil, fillFirst: 0, fillSecond: ""), (42, ""))
    checkZip(zipLongest(nil, nil, fillFirst: 0, fillSecond: ""), nil)

    func failing() -> Int {
      Issue.record("Fill function should not be called")
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

private func checkZip<T: Equatable, U: Equatable>(
  _ lhs: (T, U)?,
  _ rhs: (T, U)?
) {
  #expect(lhs?.0 == rhs?.0)
  #expect(lhs?.1 == rhs?.1)
}
