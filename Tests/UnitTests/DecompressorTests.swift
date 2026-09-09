import CGGenBytecodeDecoding
import Compression
import Testing

struct DecompressorTests {
  @Test(arguments: [0, 65536])
  func roundTrip(count: Int) throws {
    let input = (0..<count).map { UInt8(truncatingIfNeeded: $0) }
    let compressed = try compress(input)
    #expect(try decompress(compressed, expectedSize: count) == input)
  }

  @Test(arguments: [65, 67])
  func wrongSizeThrows(expectedSize: Int) throws {
    let compressed = try compress(Array(0..<66))
    #expect(throws: DecompressionError.self) {
      try decompress(compressed, expectedSize: expectedSize)
    }
  }

  @Test(arguments: [66, 65536])
  func truncatedStreamThrows(size: Int) throws {
    let input = (0..<size).map { UInt8(truncatingIfNeeded: $0) }
    let compressed = try compress(input)
    for count in 0..<compressed.count {
      #expect(throws: DecompressionError.self) {
        try decompress(Array(compressed.prefix(count)), expectedSize: size)
      }
    }
  }

  @Test func corruptStreamThrows() {
    #expect(throws: DecompressionError.self) {
      try decompress([0, 0, 0, 0], expectedSize: 66)
    }
  }
}

private func compress(_ input: [UInt8]) throws -> [UInt8] {
  let source = input.isEmpty ? [0] : input
  var compressed = [UInt8](repeating: 0, count: input.count * 2 + 1024)
  let count = source.withUnsafeBufferPointer { source in
    compressed.withUnsafeMutableBufferPointer { destination in
      compression_encode_buffer(
        destination.baseAddress!, destination.count,
        source.baseAddress!, input.count, nil, COMPRESSION_LZFSE
      )
    }
  }
  try #require(count > 0)
  return Array(compressed.prefix(count))
}

private func decompress(
  _ compressed: [UInt8],
  expectedSize: Int
) throws -> [UInt8] {
  let source = compressed.isEmpty ? [0] : compressed
  return try source.withUnsafeBufferPointer { buffer in
    try decompressBytecode(
      buffer.baseAddress!, compressed.count, expectedSize
    )
  }
}
