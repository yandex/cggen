import Testing

import CGGenCore
@preconcurrency import Parsing

@Suite struct ParserTests {
  @Test func dictionaryKey() throws {
    var dict = ["a": "1", "b": "2", "x": "99", "y": "100"]

    // Test throws when key not found
    #expect(throws: ParseError.self) {
      _ = try DicitionaryKey<String, String>("missing").parse(&dict)
    }

    // Test returns value when key exists
    let result = try DicitionaryKey<String, String>("a").parse(&dict)
    #expect(result == "1")
    #expect(dict == ["b": "2", "x": "99", "y": "100"])

    // Test Optionally returns nil for missing key
    let optional1 = Optionally { DicitionaryKey<String, String>("c") }
      .parse(&dict)
    #expect(optional1 == nil)
    #expect(dict == ["b": "2", "x": "99", "y": "100"])

    // Test Optionally returns value for existing key
    let optional2 = Optionally { DicitionaryKey<String, String>("b") }
      .parse(&dict)
    #expect(optional2 == "2")
    #expect(dict == ["x": "99", "y": "100"])
  }
}
