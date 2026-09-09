import CGGenBytecode
import CoreGraphics
import Dispatch
import Foundation
import Testing

@_spi(CGGenInternal) @_spi(Generator) import CGGenRTSupport

struct BytecodeCacheTests {
  @Test func sharedSourceIdentityChangesWithMutationOrSize() {
    var source: [UInt8] = [1, 2, 3]
    let first = BytecodeStorage.shared(bytes: source, decompressedSize: 3)
    let second = BytecodeStorage.shared(bytes: source, decompressedSize: 3)
    #expect(first === second)
    source[0] = 9
    let changed = BytecodeStorage.shared(bytes: source, decompressedSize: 3)
    #expect(changed !== first)
    let differentSize = BytecodeStorage.shared(
      bytes: source,
      decompressedSize: 4
    )
    #expect(differentSize !== changed)
  }

  @Test func cacheRetainsSourceUntilEviction() throws {
    let decoder = RecordingDecoder()
    let cache = BytecodeCache(decompress: decoder.decode)
    weak var weakStorage: BytecodeStorage?
    let decoded: [UInt8]
    do {
      let storage = BytecodeStorage(bytes: [1, 2, 3], decompressedSize: 3)
      weakStorage = storage
      decoded = try cache.decode(storage)
    }
    #expect(weakStorage != nil)
    cache.removeAll()
    #expect(weakStorage == nil)
    #expect(decoded == [1, 2, 3])
  }

  @Test func sourceMutationCannotChangeCachedOrPendingBytes() throws {
    let cache = BytecodeCache(decompress: { bytes, _ in bytes })
    var source: [UInt8] = [1, 2, 3]
    let first = BytecodeStorage(bytes: source, decompressedSize: 3)
    source[0] = 9
    let second = BytecodeStorage(bytes: source, decompressedSize: 3)
    #expect(try cache.decode(first) == [1, 2, 3])
    #expect(try cache.decode(second) == [9, 2, 3])
    cache.removeAll()
    #expect(try cache.decode(first) == [1, 2, 3])
  }

  @Test func concurrentRequestsDecodeOnce() {
    let decoder = RecordingDecoder()
    let cache = BytecodeCache(decompress: decoder.decode)
    let storage = BytecodeStorage(bytes: [1, 2, 3], decompressedSize: 3)
    DispatchQueue.concurrentPerform(iterations: 64) { _ in
      do {
        #expect(try cache.decode(storage) == [1, 2, 3])
      } catch {
        Issue.record(error)
      }
    }
    #expect(decoder.calls == 1)
  }

  @Test func evictionRecomputesWithoutInvalidatingReturnedBytes() throws {
    let decoder = RecordingDecoder()
    let cache = BytecodeCache(decompress: decoder.decode)
    let storage = BytecodeStorage(bytes: [1, 2, 3], decompressedSize: 3)
    let first = try cache.decode(storage)
    cache.removeAll()
    #expect(try cache.decode(storage) == first)
    #expect(decoder.calls == 2)
  }

  @Test func failedDecodeCanBeRetried() throws {
    let decoder = RecordingDecoder(failFirst: true)
    let cache = BytecodeCache(decompress: decoder.decode)
    let storage = BytecodeStorage(bytes: [1, 2, 3], decompressedSize: 3)
    #expect(throws: DecoderFailure.self) { try cache.decode(storage) }
    #expect(try cache.decode(storage) == [1, 2, 3])
    #expect(try cache.decode(storage) == [1, 2, 3])
    #expect(decoder.calls == 2)
  }

  @Test func equalDrawingsKeepValueEqualityAcrossStorageOwners() {
    let first = BytecodeStorage(bytes: [1, 2, 3], decompressedSize: 3)
    let second = BytecodeStorage(bytes: [1, 2, 3], decompressedSize: 3)
    let lhs = Drawing(
      width: 10, height: 10, storage: first, startIndex: 0, endIndex: 2
    )
    let rhs = Drawing(
      width: 10, height: 10, storage: second, startIndex: 0, endIndex: 2
    )
    #expect(lhs == rhs)
    #expect(Set([lhs, rhs]).count == 1)
  }

  @Test func reusedSourceAddressDoesNotReuseDecodedPath() throws {
    let firstBytes = lineBytecode(x: 10, y: 20)
    let secondBytes = lineBytecode(x: 30, y: 40)
    let firstCompressed = try compressed(firstBytes)
    let secondCompressed = try compressed(secondBytes)
    var source = [UInt8](
      repeating: 0, count: max(firstCompressed.count, secondCompressed.count)
    )
    source.withUnsafeMutableBufferPointer { buffer in
      for (index, byte) in firstCompressed.enumerated() {
        buffer[index] = byte
      }
      let first = createBytecodeStorage(
        buffer.baseAddress!, firstCompressed.count, firstBytes.count
      )
      let firstPath = CGMutablePath()
      applyPathBytecode(firstPath, first, 0, firstBytes.count - 1)
      releaseBytecodeStorage(first)

      for (index, byte) in secondCompressed
        .enumerated() {
        buffer[index] = byte
      }
      let second = createBytecodeStorage(
        buffer.baseAddress!, secondCompressed.count, secondBytes.count
      )
      defer { releaseBytecodeStorage(second) }
      let secondPath = CGMutablePath()
      applyPathBytecode(secondPath, second, 0, secondBytes.count - 1)
      #expect(firstPath.currentPoint == CGPoint(x: 10, y: 20))
      #expect(secondPath.currentPoint == CGPoint(x: 30, y: 40))
    }
  }

  @Test(arguments: [(-1, 7), (0, 8), (3, 1), (Int.max, Int.max)])
  func invalidDrawingRangeThrows(start: Int, end: Int) throws {
    let bytes = try compressed([UInt8](repeating: 0, count: 8))
    let context = try #require(CGContext(
      data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    #expect(throws: BytecodeRangeError.self) {
      try runMergedBytecode(fromData: bytes, context, 8, start, end)
    }
  }

  @Test func emptyPathRangeAtEndOfBlockIsValid() throws {
    let bytes = lineBytecode(x: 10, y: 20)
    let storage = try BytecodeStorage(
      bytes: Array(compressed(bytes)), decompressedSize: bytes.count
    )
    let drawing = Drawing.Path(
      storage: storage, startIndex: Int32(bytes.count),
      endIndex: Int32(bytes.count - 1)
    )
    let path = CGMutablePath()
    drawing.apply(to: path)
    #expect(path.isEmpty)
  }
}

private func compressed(_ bytes: [UInt8]) throws -> Data {
  try (Data(bytes) as NSData).compressed(using: .lzfse) as Data
}

private func lineBytecode(x: Float, y: Float) -> [UInt8] {
  [PathCommand.moveTo.rawValue] +
    [UInt8](repeating: 0, count: 8) + [PathCommand.lineTo.rawValue] +
    [x, y].flatMap { value in
      (0..<4).map { UInt8(truncatingIfNeeded: value.bitPattern >> ($0 * 8)) }
    }
}

private enum DecoderFailure: Swift.Error {
  case injected
}

private final class RecordingDecoder: @unchecked Sendable {
  private let lock = NSLock()
  private var callCount = 0
  private let failFirst: Bool

  init(failFirst: Bool = false) {
    self.failFirst = failFirst
  }

  var calls: Int {
    lock.lock()
    defer { lock.unlock() }
    return callCount
  }

  func decode(_ bytes: [UInt8], _: Int) throws -> [UInt8] {
    lock.lock()
    defer { lock.unlock() }
    callCount += 1
    if failFirst, callCount == 1 { throw DecoderFailure.injected }
    return bytes
  }
}
