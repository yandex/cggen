import CoreGraphics

/// A drawable vector graphic representation backed by compressed bytecode.
///
/// This struct is designed for minimal memory footprint.
public struct Drawing: Sendable, Equatable, Hashable {
  var width: Float
  var height: Float
  var bytecode: BytecodeProcedure

  struct BytecodeProcedure: Equatable, Hashable {
    var storage: BytecodeStorage
    var startIndex: Int32
    var endIndex: Int32

    static func ==(lhs: Self, rhs: Self) -> Bool {
      lhs.startIndex == rhs.startIndex && lhs.endIndex == rhs.endIndex &&
        lhs.storage.hasSameContents(as: rhs.storage)
    }

    func hash(into hasher: inout Hasher) {
      storage.hashContents(into: &hasher)
      hasher.combine(startIndex)
      hasher.combine(endIndex)
    }
  }

  @_spi(Generator) public init(
    width: Float,
    height: Float,
    bytecodeArray: [UInt8],
    decompressedSize: Int32,
    startIndex: Int32,
    endIndex: Int32
  ) {
    self.init(
      width: width, height: height,
      storage: BytecodeStorage.shared(
        bytes: bytecodeArray, decompressedSize: Int(decompressedSize)
      ),
      startIndex: startIndex, endIndex: endIndex
    )
  }

  @_spi(Generator) public init(
    width: Float,
    height: Float,
    storage: BytecodeStorage,
    startIndex: Int32,
    endIndex: Int32
  ) {
    self.width = width
    self.height = height
    bytecode = BytecodeProcedure(
      storage: storage, startIndex: startIndex, endIndex: endIndex
    )
  }

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
      storage: bytecode.storage,
      startIndex: Int(bytecode.startIndex),
      endIndex: Int(bytecode.endIndex)
    )
  }
}

// MARK: - Drawing.Path

extension Drawing {
  /// A path representation backed by compressed bytecode.
  public struct Path: Sendable, Equatable, Hashable {
    var bytecode: BytecodeProcedure

    @_spi(Generator) public init(
      bytecodeArray: [UInt8],
      decompressedSize: Int32,
      startIndex: Int32,
      endIndex: Int32
    ) {
      self.init(
        storage: BytecodeStorage.shared(
          bytes: bytecodeArray, decompressedSize: Int(decompressedSize)
        ),
        startIndex: startIndex, endIndex: endIndex
      )
    }

    @_spi(Generator) public init(
      storage: BytecodeStorage,
      startIndex: Int32,
      endIndex: Int32
    ) {
      bytecode = BytecodeProcedure(
        storage: storage, startIndex: startIndex, endIndex: endIndex
      )
    }

    /// Applies the path to a mutable path object.
    /// - Parameter path: The mutable path to apply this path to.
    public func apply(to path: CGMutablePath) {
      runCompressedPathBytecode(
        path: path,
        storage: bytecode.storage,
        startIndex: Int(bytecode.startIndex),
        endIndex: Int(bytecode.endIndex)
      )
    }
  }
}
