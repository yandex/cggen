import CGGenBytecodeDecoding
import Foundation

@_spi(Generator)
public final class BytecodeStorage: NSObject, Sendable {
  let bytes: [UInt8]
  let decompressedSize: Int

  public init(bytes: [UInt8], decompressedSize: Int) {
    self.bytes = bytes
    self.decompressedSize = decompressedSize
  }

  public static func shared(
    bytes: [UInt8], decompressedSize: Int
  ) -> BytecodeStorage {
    sourceStorageCache.storage(bytes: bytes, decompressedSize: decompressedSize)
  }

  func slice(startIndex: Int, endIndex: Int) throws -> ArraySlice<UInt8> {
    let decoded = try bytecodeCache.decode(self)
    guard startIndex >= 0, startIndex <= decoded.count,
          endIndex >= startIndex - 1, endIndex < decoded.count else {
      throw BytecodeRangeError(
        startIndex: startIndex, endIndex: endIndex, count: decoded.count
      )
    }
    return decoded[startIndex..<endIndex + 1]
  }

  func hasSameContents(as other: BytecodeStorage) -> Bool {
    self === other ||
      (decompressedSize == other.decompressedSize && bytes == other.bytes)
  }

  func hashContents(into hasher: inout Hasher) {
    hasher.combine(decompressedSize)
    hasher.combine(bytes)
  }
}

public struct BytecodeRangeError: Swift.Error {
  public var startIndex: Int
  public var endIndex: Int
  public var count: Int
}

@_spi(CGGenInternal)
public final class BytecodeCache: @unchecked Sendable {
  private final class Buffer {
    var bytes: [UInt8]

    init(_ bytes: [UInt8]) {
      self.bytes = bytes
    }
  }

  // The lock covers lookup, decoding, insertion, and eviction as one operation.
  private let lock = NSLock()
  private let cache = NSCache<BytecodeStorage, Buffer>()
  private let decompress: @Sendable ([UInt8], Int) throws -> [UInt8]

  public init(
    decompress: @escaping @Sendable ([UInt8], Int) throws -> [UInt8] =
      decompressBytecode
  ) {
    self.decompress = decompress
  }

  public func decode(_ storage: BytecodeStorage) throws -> [UInt8] {
    lock.lock()
    defer { lock.unlock() }
    if let buffer = cache.object(forKey: storage) {
      return buffer.bytes
    }
    let bytes = try decompress(storage.bytes, storage.decompressedSize)
    cache.setObject(Buffer(bytes), forKey: storage, cost: bytes.count)
    return bytes
  }

  public func removeAll() {
    lock.lock()
    defer { lock.unlock() }
    cache.removeAllObjects()
  }
}

private let bytecodeCache = BytecodeCache()

private final class SourceStorageCache: @unchecked Sendable {
  private let lock = NSLock()
  private let cache = NSCache<NSNumber, BytecodeStorage>()

  func storage(bytes: [UInt8], decompressedSize: Int) -> BytecodeStorage {
    // UInt8 arrays have native contiguous storage; retaining the array keeps
    // its allocation alive for as long as its address is registered here.
    unsafe bytes.withUnsafeBufferPointer { buffer in
      let key = NSNumber(value: UInt(bitPattern: buffer.baseAddress))
      lock.lock()
      defer { lock.unlock() }
      if let storage = cache.object(forKey: key),
         storage.bytes.count == bytes.count,
         storage.decompressedSize == decompressedSize {
        return storage
      }
      let storage = BytecodeStorage(
        bytes: bytes,
        decompressedSize: decompressedSize
      )
      cache.setObject(storage, forKey: key, cost: bytes.count)
      return storage
    }
  }
}

private let sourceStorageCache = SourceStorageCache()
