import Compression

public enum DecompressionError: Swift.Error {
  case invalidLengths
  case decompressionFailed
  case unexpectedSize(expected: Int, actual: Int)
}

public func decompressBytecode(
  _ start: UnsafePointer<UInt8>,
  _ compressedLen: Int,
  _ decompressedLen: Int
) throws -> [UInt8] {
  guard compressedLen > 0, decompressedLen >= 0 else {
    throw DecompressionError.invalidLengths
  }

  // A nonempty destination lets the decoder validate an empty output stream.
  return try [UInt8](unsafeUninitializedCapacity: max(1, decompressedLen)) {
    buffer, initializedCount in
    let destination = buffer.baseAddress!
    var stream = compression_stream(
      dst_ptr: destination,
      dst_size: 0,
      src_ptr: start,
      src_size: 0,
      state: nil
    )
    guard compression_stream_init(
      &stream,
      COMPRESSION_STREAM_DECODE,
      COMPRESSION_LZFSE
    ) == COMPRESSION_STATUS_OK else {
      throw DecompressionError.decompressionFailed
    }
    defer { compression_stream_destroy(&stream) }

    stream.dst_ptr = destination
    stream.dst_size = buffer.count
    stream.src_ptr = start
    stream.src_size = compressedLen
    let status = compression_stream_process(
      &stream,
      Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
    )
    initializedCount = buffer.count - stream.dst_size
    guard status == COMPRESSION_STATUS_END else {
      throw DecompressionError.decompressionFailed
    }
    guard initializedCount == decompressedLen else {
      throw DecompressionError.unexpectedSize(
        expected: decompressedLen,
        actual: initializedCount
      )
    }
  }
}
