import Compression

public enum DecompressionError: Swift.Error {
  case invalidLengths
  case decompressionFailed
  case unexpectedSize(expected: Int, actual: Int)
}

public func decompressBytecode(
  _ bytes: [UInt8],
  decompressedSize: Int
) throws -> [UInt8] {
  guard !bytes.isEmpty else { throw DecompressionError.invalidLengths }
  return try unsafe bytes.withUnsafeBufferPointer { buffer in
    try unsafe decompressBytecode(
      buffer.baseAddress!, buffer.count, decompressedSize
    )
  }
}

/// The source must contain `compressedLen` initialized bytes during this call.
@unsafe
public func decompressBytecode(
  _ start: UnsafePointer<UInt8>,
  _ compressedLen: Int,
  _ decompressedLen: Int
) throws -> [UInt8] {
  guard compressedLen > 0, decompressedLen >= 0 else {
    throw DecompressionError.invalidLengths
  }

  // A nonempty destination lets the decoder validate an empty output stream.
  return try unsafe [UInt8](unsafeUninitializedCapacity: max(
    1,
    decompressedLen
  )) {
    buffer, initializedCount in
    let destination = buffer.baseAddress!
    var stream = unsafe compression_stream(
      dst_ptr: destination,
      dst_size: 0,
      src_ptr: start,
      src_size: 0,
      state: nil
    )
    guard unsafe compression_stream_init(
      &stream,
      COMPRESSION_STREAM_DECODE,
      COMPRESSION_LZFSE
    ) == COMPRESSION_STATUS_OK else {
      throw DecompressionError.decompressionFailed
    }
    defer { unsafe compression_stream_destroy(&stream) }

    unsafe stream.dst_ptr = destination
    unsafe stream.dst_size = buffer.count
    unsafe stream.src_ptr = start
    unsafe stream.src_size = compressedLen
    let status = unsafe compression_stream_process(
      &stream,
      Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
    )
    initializedCount = unsafe buffer.count - stream.dst_size
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
