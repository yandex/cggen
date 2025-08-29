import Compression
import Foundation

public func decompressBytecode(
  _ start: UnsafePointer<UInt8>,
  _ compressedLen: Int,
  _ decompressedLen: Int
) throws -> [UInt8] {
  let decodedDestinationBuffer = UnsafeMutablePointer<UInt8>
    .allocate(capacity: decompressedLen)

  let decompressedSize = compression_decode_buffer(
    decodedDestinationBuffer,
    decompressedLen,
    start,
    compressedLen,
    nil,
    COMPRESSION_LZFSE
  )

  return [UInt8](UnsafeBufferPointer(
    start: decodedDestinationBuffer,
    count: decompressedSize
  ))
}
