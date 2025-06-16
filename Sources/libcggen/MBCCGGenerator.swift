import Compression
import Foundation

import BCCommon
import CGGen

struct MBCCGGenerator: CoreGraphicsGenerator {
  typealias ImagePossition = (Int, Int)

  let params: GenerationParams
  let headerImportPath: String?
  let outputs: [Output]

  // Computed unified bytecode data
  private let unifiedBytecodeData: UnifiedBytecodeData

  struct UnifiedBytecodeData {
    let compressedBytecode: [UInt8]
    let decompressedSize: Int
    let compressedSize: Int
    let imagePositions: [(Image, ImagePossition)]
    let pathPositions: [(PathRoutine, ImagePossition)]
  }

  init(
    params: GenerationParams,
    headerImportPath: String?,
    outputs: [Output]
  ) throws {
    self.params = params
    self.headerImportPath = headerImportPath
    self.outputs = outputs
    unifiedBytecodeData = try Self.generateUnifiedBytecode(outputs: outputs)
  }

  private static func generateUnifiedBytecode(outputs: [Output]) throws
    -> UnifiedBytecodeData {
    var mergedBytecodes: [UInt8] = []
    var imagePositions: [(Image, ImagePossition)] = []
    var pathPositions: [(PathRoutine, ImagePossition)] = []

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
    let compressedSize = compressedBytecode.count

    return UnifiedBytecodeData(
      compressedBytecode: compressedBytecode,
      decompressedSize: decompressedSize,
      compressedSize: compressedSize,
      imagePositions: imagePositions,
      pathPositions: pathPositions
    )
  }

  func filePreamble() -> String {
    let importLine = headerImportPath.map { "#import \"\($0)\"\n" } ?? ""

    return """
    \(importLine)
    void runMergedBytecode(CGContextRef context, const uint8_t* arr, int decompressedLen, int compressedLen, int startIndex, int endIndex);
    void runPathBytecode(CGMutablePathRef path, const uint8_t* arr, int len);
    void runMergedPathBytecode(CGMutablePathRef path, const uint8_t* arr, int decompressedLen, int compressedLen, int startIndex, int endIndex);

    static const uint8_t mergedBytecodes[];
    """
  }

  func generateImageFunctions() throws -> String {
    let imageFunctions = unifiedBytecodeData.imagePositions
      .map { image, position in
        generateImageFunctionForMergedBytecode(
          image: image,
          imagePossition: position,
          decompressedSize: unifiedBytecodeData.decompressedSize,
          compressedSize: unifiedBytecodeData.compressedSize
        )
      }.joined(separator: "\n\n")

    return imageFunctions
  }

  func generatePathFunctions() throws -> String {
    guard !unifiedBytecodeData.pathPositions.isEmpty else { return "" }

    let pathFunctions = unifiedBytecodeData.pathPositions
      .map { path, position in
        let camel = path.id.upperCamelCase
        return """
        void \(params.prefix)\(camel)Path(CGMutablePathRef path) {
          runMergedPathBytecode(path, mergedBytecodes, \(
            unifiedBytecodeData
              .decompressedSize
        ), \(unifiedBytecodeData.compressedSize), \(
          position
            .0
        ), \(position.1));
        }
        """
        }.joined(separator: "\n\n")

    return pathFunctions
  }

  func fileEnding() throws -> String {
    """
    static const uint8_t mergedBytecodes[] = {
    \(formatBytecodeArray(unifiedBytecodeData.compressedBytecode))
    };
    """
  }
}

extension MBCCGGenerator {
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

  func generateImageFunctionForMergedBytecode(
    image: Image,
    imagePossition: ImagePossition,
    decompressedSize: Int,
    compressedSize: Int
  ) -> String {
    """
    \(params.style.drawingHandlerPrefix)void \(params.prefix)Draw\(
      image.name.upperCamelCase
    )ImageInContext(CGContextRef context) {
      runMergedBytecode(context, mergedBytecodes, \(decompressedSize), \(
        compressedSize
      ), \(
      imagePossition
        .0
    ), \(imagePossition.1));
    }
    """ + params.descriptorLines(for: image).joined(separator: "\n")
  }
}

func compressBytecode(_ bytecode: [UInt8]) throws -> [UInt8] {
  let pageSize = 128
  let sourceData = Data(bytecode)
  var compressedData = Data()

  let outputFilter = try OutputFilter(
    .compress,
    using: .lzfse,
    writingTo: { (data: Data?) in
      if let data {
        compressedData.append(data)
      }
    }
  )

  var index = 0
  let bufferSize = sourceData.count

  while true {
    let rangeLength = min(pageSize, bufferSize - index)

    let subdata = sourceData.subdata(in: index..<index + rangeLength)
    index += rangeLength

    try outputFilter.write(subdata)

    if rangeLength == 0 { break }
  }
  return [UInt8](compressedData)
}
