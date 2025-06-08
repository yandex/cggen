import BCCommon
import Foundation

struct SwiftCGGenerator: CoreGraphicsGenerator {
  typealias ImagePosition = (Int, Int)

  let params: GenerationParams

  init(params: GenerationParams) {
    self.params = params
  }

  func filePreamble() -> String {
    """
    import CoreGraphics
    @_spi(Generator) import CGGenRuntimeSupport

    typealias Drawing = CGGenRuntimeSupport.Drawing
    """
  }

  func generateImageFunctions(images: [Image]) throws -> String {
    let (bytecodeMergeArray, positions, decompressedSize) =
      try generateMergedBytecodeArray(images: images)

    // Generate Drawing namespace extension for swift-friendly style
    let drawingExtension = generateDrawingExtension(
      images: images,
      positions: positions,
      decompressedSize: decompressedSize
    )

    return [drawingExtension, bytecodeMergeArray]
      .joined(separator: "\n\n")
  }

  func generatePathFuncton(path: PathRoutine) -> String {
    let bytecodeName = "\(path.id.lowerCamelCase)Bytecode"
    let bytecode = generatePathBytecode(route: path)
    let camel = path.id.upperCamelCase
    let functionName = "\(params.prefix.lowercased())\(camel)Path"

    return """
    private let \(bytecodeName): [UInt8] = [
      \(bytecode.map { String(format: "0x%02X", $0) }.joined(separator: ", "))
    ]

    public func \(functionName)(in path: CGMutablePath) {
      runPathBytecode(path: path, bytecodeArray: \(bytecodeName))
    }
    """
  }

  func fileEnding() -> String {
    ""
  }
}

// MARK: - Image and Bytecode Generation

extension SwiftCGGenerator {
  func generateMergedBytecodeArray(images: [Image]) throws
    -> (String, [ImagePosition], Int) {
    var imagePositions: [ImagePosition] = []
    var mergedBytecodes: [UInt8] = []
    let bytecodeName = "mergedBytecodes"

    for image in images {
      let bytecode = generateRouteBytecode(route: image.route)

      imagePositions.append((
        mergedBytecodes.count,
        mergedBytecodes.count + bytecode.count - 1
      ))
      mergedBytecodes += bytecode
    }

    let compressedBytecode = try compressBytecode(mergedBytecodes)
    let bytecodeString = """
    private let \(bytecodeName): [UInt8] = [
    \(formatBytecodeArray(compressedBytecode))
    ]
    """

    return (
      bytecodeString,
      imagePositions,
      mergedBytecodes.count
    )
  }

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

  private func generateDrawingExtension(
    images: [Image],
    positions: [ImagePosition],
    decompressedSize: Int
  ) -> String {
    let staticProperties = zip(images, positions).map { image, position in
      let propertyName = image.name.lowerCamelCase
      let size = image.route.boundingRect.size
      return """
        static let \(propertyName) = Drawing(
          width: \(size.width),
          height: \(size.height),
          bytecodeArray: mergedBytecodes,
          decompressedSize: \(decompressedSize),
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
}
