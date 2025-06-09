import BCCommon
import Foundation

struct SwiftCGGenerator: CoreGraphicsGenerator {
  typealias ImagePosition = (Int, Int)

  let params: GenerationParams
  let outputs: [Output]

  // Computed unified bytecode data
  private let unifiedBytecodeData: UnifiedBytecodeData

  struct UnifiedBytecodeData {
    let compressedBytecode: [UInt8]
    let decompressedSize: Int
    let imagePositions: [(Image, ImagePosition)]
    let pathPositions: [(PathRoutine, ImagePosition)]
  }

  init(params: GenerationParams, outputs: [Output]) throws {
    self.params = params
    self.outputs = outputs
    unifiedBytecodeData = try Self.generateUnifiedBytecode(outputs: outputs)
  }

  private static func generateUnifiedBytecode(outputs: [Output]) throws
    -> UnifiedBytecodeData {
    var mergedBytecodes: [UInt8] = []
    var imagePositions: [(Image, ImagePosition)] = []
    var pathPositions: [(PathRoutine, ImagePosition)] = []

    // Process images
    let images = outputs.map(\.image)
    for image in images {
      let bytecode = generateRouteBytecode(route: image.route)
      let position = (
        mergedBytecodes.count,
        mergedBytecodes.count + bytecode.count - 1
      )
      imagePositions.append((image, position))
      mergedBytecodes += bytecode
    }

    // Process paths
    let paths = outputs.flatMap(\.pathRoutines)
    for path in paths {
      let bytecode = generatePathBytecode(route: path)
      let position = (
        mergedBytecodes.count,
        mergedBytecodes.count + bytecode.count - 1
      )
      pathPositions.append((path, position))
      mergedBytecodes += bytecode
    }

    let decompressedSize = mergedBytecodes.count
    let compressedBytecode = try compressBytecode(mergedBytecodes)

    return UnifiedBytecodeData(
      compressedBytecode: compressedBytecode,
      decompressedSize: decompressedSize,
      imagePositions: imagePositions,
      pathPositions: pathPositions
    )
  }

  func filePreamble() -> String {
    """
    import CoreGraphics
    @_spi(Generator) import CGGenRuntimeSupport

    typealias Drawing = CGGenRuntimeSupport.Drawing
    """
  }

  func generateImageFunctions() throws -> String {
    let staticProperties = unifiedBytecodeData.imagePositions
      .map { image, position in
        let propertyName = image.name.lowerCamelCase
        let size = image.route.boundingRect.size
        return """
          static let \(propertyName) = Drawing(
            width: \(size.width),
            height: \(size.height),
            bytecodeArray: mergedBytecodes,
            decompressedSize: \(unifiedBytecodeData.decompressedSize),
            startIndex: \(position.0),
            endIndex: \(position.1)
          )
        """
      }.joined(separator: "\n")

    return """
    extension Drawing {
    \(staticProperties)
    }
    """
  }

  func generatePathFunctions() throws -> String {
    guard !unifiedBytecodeData.pathPositions.isEmpty else { return "" }

    let staticProperties = unifiedBytecodeData.pathPositions
      .map { path, position in
        let propertyName = path.id.lowerCamelCase
        return """
          static let \(propertyName) = Drawing.Path(
            bytecodeArray: mergedBytecodes,
            decompressedSize: \(unifiedBytecodeData.decompressedSize),
            startIndex: \(position.0),
            endIndex: \(position.1)
          )
        """
      }.joined(separator: "\n")

    return """

    // MARK: - Paths

    extension Drawing.Path {
    \(staticProperties)
    }
    """
  }

  func fileEnding() throws -> String {
    """
    private let mergedBytecodes: [UInt8] = [
    \(formatBytecodeArray(unifiedBytecodeData.compressedBytecode))
    ]
    """
  }
}

// MARK: - Helpers

extension SwiftCGGenerator {
  private func formatBytecodeArray(_ bytes: [UInt8]) -> String {
    // Format bytecode array with line breaks every 12 bytes for readability
    let bytesPerLine = 12
    var lines: [String] = []

    for i in stride(from: 0, to: bytes.count, by: bytesPerLine) {
      let end = min(i + bytesPerLine, bytes.count)
      let lineBytes = bytes[i..<end].map { String(format: "0x%02X", $0) }
        .joined(separator: ", ")
      let indent = "  " // Consistent 2 space indentation
      lines.append(indent + lineBytes)
    }

    return lines.joined(separator: ",\n")
  }
}
