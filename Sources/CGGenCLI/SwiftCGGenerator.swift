import BCCommon
import CGGenIR
import CGGenRTSupport
import Foundation

private struct UnifiedBytecodeData {
  let compressedBytecode: [UInt8]
  let decompressedSize: Int
  let imagePositions: [(Image, (start: Int, end: Int))]
  let pathPositions: [(PathRoutine, (start: Int, end: Int))]
}

func generateSwiftFile(
  params _: GenerationParams,
  outputs: [Output]
) throws -> String {
  let unifiedBytecodeData = try generateUnifiedBytecode(outputs: outputs)

  var sections = [String]()

  // Header comment
  sections.append(commonHeaderPrefix)

  // Imports
  sections.append("""
  import CoreGraphics
  @_spi(Generator) import CGGenRTSupport

  typealias Drawing = CGGenRTSupport.Drawing
  """)

  // Image functions
  sections
    .append(generateImageFunctions(unifiedBytecodeData: unifiedBytecodeData))

  // Path functions
  let pathFunctions =
    generatePathFunctions(unifiedBytecodeData: unifiedBytecodeData)
  if !pathFunctions.isEmpty {
    sections.append(pathFunctions)
  }

  // Bytecode array
  sections.append("""
  private let mergedBytecodes: [UInt8] = [
  \(formatBytecodeArray(unifiedBytecodeData.compressedBytecode))
  ]
  """)

  return sections.joined(separator: "\n\n") + "\n"
}

private func generateUnifiedBytecode(outputs: [Output]) throws
  -> UnifiedBytecodeData {
  var mergedBytecodes: [UInt8] = []
  var imagePositions: [(Image, (start: Int, end: Int))] = []
  var pathPositions: [(PathRoutine, (start: Int, end: Int))] = []

  // Process images
  let images = outputs.map(\.image)
  for image in images {
    let bytecode = generateRouteBytecode(route: image.route)
    let position = (
      start: mergedBytecodes.count,
      end: mergedBytecodes.count + bytecode.count - 1
    )
    imagePositions.append((image, position))
    mergedBytecodes += bytecode
  }

  // Process paths
  let paths = outputs.flatMap(\.pathRoutines)
  for path in paths {
    let bytecode = generatePathBytecode(route: path)
    let position = (
      start: mergedBytecodes.count,
      end: mergedBytecodes.count + bytecode.count - 1
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

private func generateImageFunctions(unifiedBytecodeData: UnifiedBytecodeData)
  -> String {
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
          startIndex: \(position.start),
          endIndex: \(position.end)
        )
      """
    }.joined(separator: "\n")

  return """
  extension Drawing {
  \(staticProperties)
  }
  """
}

private func generatePathFunctions(unifiedBytecodeData: UnifiedBytecodeData)
  -> String {
  guard !unifiedBytecodeData.pathPositions.isEmpty else { return "" }

  let staticProperties = unifiedBytecodeData.pathPositions
    .map { path, position in
      let propertyName = path.id.lowerCamelCase
      return """
        static let \(propertyName) = Drawing.Path(
          bytecodeArray: mergedBytecodes,
          decompressedSize: \(unifiedBytecodeData.decompressedSize),
          startIndex: \(position.start),
          endIndex: \(position.end)
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
