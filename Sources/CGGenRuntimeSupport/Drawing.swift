import CoreGraphics

/// A drawable vector graphic representation backed by compressed bytecode.
///
/// This struct is designed for minimal memory footprint.
public struct Drawing: Sendable, Equatable, Hashable {
  // Implementation note: Using Float (4 bytes) vs CGFloat (8 bytes) and Int32
  // (4 bytes) vs Int (8 bytes) reduces memory from 48 to 28 bytes per instance.
  @usableFromInline var width: Float
  @usableFromInline var height: Float
  @usableFromInline var bytecode: BytecodeProcedure

  @usableFromInline
  struct BytecodeProcedure: Sendable, Equatable, Hashable {
    @usableFromInline var bytecodeArray: [UInt8]
    @usableFromInline var decompressedSize: Int32
    @usableFromInline var startIndex: Int32
    @usableFromInline var endIndex: Int32

    @inlinable
    init(
      bytecodeArray: [UInt8],
      decompressedSize: Int32,
      startIndex: Int32,
      endIndex: Int32
    ) {
      self.bytecodeArray = bytecodeArray
      self.decompressedSize = decompressedSize
      self.startIndex = startIndex
      self.endIndex = endIndex
    }
  }

  @inlinable
  @_spi(Generator) public init(
    width: Float,
    height: Float,
    bytecodeArray: [UInt8],
    decompressedSize: Int32,
    startIndex: Int32,
    endIndex: Int32
  ) {
    self.width = width
    self.height = height
    bytecode = BytecodeProcedure(
      bytecodeArray: bytecodeArray,
      decompressedSize: decompressedSize,
      startIndex: startIndex,
      endIndex: endIndex
    )
  }

  @inlinable
  init(width: Float, height: Float, bytecode: BytecodeProcedure) {
    self.width = width
    self.height = height
    self.bytecode = bytecode
  }

  // MARK: - Public Interface

  /// The size of the drawing in points.
  public var size: CGSize {
    CGSize(width: CGFloat(width), height: CGFloat(height))
  }

  /// Draws the vector graphic into the specified Core Graphics context.
  /// - Parameter context: The Core Graphics context to draw into.
  public func draw(in context: CGContext) {
    runCompressedBytecode(
      context: context,
      bytecodeArray: bytecode.bytecodeArray,
      decompressedSize: Int(bytecode.decompressedSize),
      startIndex: Int(bytecode.startIndex),
      endIndex: Int(bytecode.endIndex)
    )
  }
}
