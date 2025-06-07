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
    import CGGenRuntimeSupport

    typealias Drawing = CGGenRuntimeSupport.Drawing
    """
  }

  func generateImageFunctions(images: [Image]) throws -> String {
    let (bytecodeMergeArray, positions, decompressedSize, compressedSize) =
      try generateMergedBytecodeArray(images: images)

    let functions = zip(images, positions).map { image, position in
      generateImageFunctionForMergedBytecode(
        image: image,
        imagePosition: position,
        decompressedSize: decompressedSize,
        compressedSize: compressedSize
      )
    }.joined(separator: "\n\n")

    // Generate Drawing namespace extension for swift-friendly style
    let drawingExtension = generateDrawingExtension(images: images)

    return [drawingExtension, functions, bytecodeMergeArray]
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
      \(bytecodeName).withUnsafeBufferPointer { buffer in
        runPathBytecode(path, buffer.baseAddress!, Int32(\(bytecode.count)))
      }
    }
    """
  }

  func fileEnding() -> String {
    """

    // External functions from CGGenRuntimeSupport
    @_silgen_name("runMergedBytecode_swift")
    fileprivate func runMergedBytecode(
      _ context: CGContext,
      _ data: UnsafePointer<UInt8>,
      _ decompressedLen: Int32,
      _ compressedLen: Int32,
      _ startIndex: Int32,
      _ endIndex: Int32
    )

    @_silgen_name("runPathBytecode_swift")
    fileprivate func runPathBytecode(
      _ path: CGMutablePath,
      _ data: UnsafePointer<UInt8>,
      _ len: Int32
    )
    """
  }
}

// MARK: - Image and Bytecode Generation

extension SwiftCGGenerator {
  func generateImageFunctionForMergedBytecode(
    image: Image,
    imagePosition: ImagePosition,
    decompressedSize: Int,
    compressedSize: Int
  ) -> String {
    let functionName =
      "\(params.prefix.lowercased())Draw\(image.name.upperCamelCase)Image"

    return """
    private func \(functionName)(in context: CGContext) {
      mergedBytecodes.withUnsafeBufferPointer { buffer in
        runMergedBytecode(
          context,
          buffer.baseAddress!,
          \(decompressedSize),
          \(compressedSize),
          \(imagePosition.0),
          \(imagePosition.1)
        )
      }
    }
    """
  }

  func generateMergedBytecodeArray(images: [Image]) throws
    -> (String, [ImagePosition], Int, Int) {
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
      mergedBytecodes.count,
      compressedBytecode.count
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

  private func generateDrawingExtension(images: [Image]) -> String {
    let staticProperties = images.map { image in
      let propertyName = image.name.lowerCamelCase
      let functionName =
        "\(params.prefix.lowercased())Draw\(image.name.upperCamelCase)Image"
      let size = image.route.boundingRect.size
      return """
        static let \(propertyName) = Drawing(
          size: CGSize(width: \(size.width), height: \(size.height)),
          draw: \(functionName)
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
