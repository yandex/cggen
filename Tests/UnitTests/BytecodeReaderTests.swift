import CGGenBytecodeDecoding
import Testing

struct BytecodeReaderTests {
  @Test(arguments: [-1, 5, Int.max])
  func invalidAdvanceLeavesCursorUnchanged(count: Int) throws {
    let bytes: [UInt8] = [1, 2, 3, 4]
    var bytecode = Bytecode(bytes[...])
    #expect(throws: Bytecode.ReadingError.self) {
      try bytecode.advance(count: count)
    }
    try #require(bytecode.count == 4)
    #expect(try bytecode.read(type: UInt32.self) == 0x04_03_02_01)
  }

  @Test func truncatedReadLeavesCursorUnchanged() throws {
    let bytes: [UInt8] = [1, 2, 3]
    var bytecode = Bytecode(bytes[...])
    #expect(throws: Bytecode.ReadingError.self) {
      try bytecode.read(type: UInt32.self)
    }
    #expect(bytecode.count == 3)
    #expect(try bytecode.read(type: UInt16.self) == 0x02_01)
  }

  @Test func readsUnalignedIntegersFromNonzeroSlice() throws {
    let bytes: [UInt8] = [99, 0xFF, 0xFE, 0xFF, 0x78, 0x56, 0x34, 0x12]
    var bytecode = Bytecode(bytes[1...])
    #expect(try bytecode.read(type: Int8.self) == -1)
    #expect(try bytecode.read(type: Int16.self) == -2)
    #expect(try bytecode.read(type: UInt32.self) == 0x12_34_56_78)
    #expect(bytecode.count == 0)
  }

  @Test func subrouteRetainsItsBytesIndependentlyOfParent() throws {
    var source: [UInt8] = [1, 2, 3, 4]
    var subroute: Bytecode
    do {
      var parent = Bytecode(source[...])
      subroute = try parent.advance(count: 2)
      #expect(try parent.read(type: UInt16.self) == 0x04_03)
    }
    source[0] = 9
    #expect(try subroute.read(type: UInt16.self) == 0x02_01)
    #expect(subroute.count == 0)
  }

  @Test func emptyAdvanceDoesNotConsumeInput() throws {
    var bytecode = Bytecode([1, 2][...])
    var empty = try bytecode.advance(count: 0)
    #expect(empty.count == 0)
    #expect(throws: Bytecode.ReadingError.self) {
      try empty.read(type: UInt8.self)
    }
    #expect(try bytecode.read(type: UInt16.self) == 0x02_01)
  }
}
