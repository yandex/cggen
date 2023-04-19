import Compression
import Foundation

import BCCommon

@available(macOS 10.15, *)
struct MBCCGGenerator: CoreGraphicsGenerator {
  typealias ImagePossition = (Int, Int)

  let params: GenerationParams
  let headerImportPath: String?

  func filePreamble() -> String {
    let importLine = headerImportPath.map { "#import \"\($0)\"\n" } ?? ""

    return """
    \(importLine)
    void runMergedBytecode(CGContextRef context, const uint8_t* arr, int decompressedLen, int compressedLen, int startIndex, int endIndex);
    void runPathBytecode(CGMutablePathRef path, const uint8_t* arr, int len);
    """
  }

  func generateImageFunctions(images: [Image]) throws -> String {
    let (bytecodeMergeArray, possitions, decompressedSize, compressedSize) =
      try generateMergedBytecodeArray(images: images)

    let imageFunctions = zip(images, possitions).map { image, possition in
      generateImageFunctionForMergedBytecode(
        image: image,
        imagePossition: possition,
        decompressedSize: decompressedSize,
        compressedSize: compressedSize
      )
    }.joined(separator: "\n\n")

    return [bytecodeMergeArray, imageFunctions].joined(separator: "\n\n")
  }

  func generatePathFuncton(path: PathRoutine) -> String {
    let bytecodeName = "\(path.id.lowerCamelCase)Bytecode"
    let bytecode = generatePathBytecode(route: path)
    let camel = path.id.upperCamelCase
    return """
    static const uint8_t \(bytecodeName)[] = {
      \(bytecode.map(\.description).joined(separator: ", "))
    };
    void \(params.prefix)\(camel)Path(CGMutablePathRef path) {
      runPathBytecode(path, \(bytecodeName), \(bytecode.count));
    }
    """
  }

  func fileEnding() -> String {
    ""
  }
}

@available(macOS 10.15, *)
extension MBCCGGenerator {
  func generateImageFunctionForMergedBytecode(
    image: Image,
    imagePossition: ImagePossition,
    decompressedSize: Int,
    compressedSize: Int
  ) -> String {
    return """
    \(params.style.drawingHandlerPrefix)void \(params.prefix)Draw\(
      image.name.upperCamelCase
    )ImageInContext(CGContextRef context) {
      runMergedBytecode(context, mergedBytecodes, \(decompressedSize), \(compressedSize), \(imagePossition.0), \(imagePossition.1));
    }
    """ + params.descriptorLines(for: image).joined(separator: "\n")
  }

  func generateMergedBytecodeArray(images: [Image]) throws -> (String, [ImagePossition], Int, Int) {
    var imagePossitions: [ImagePossition] = []
    var mergedBytecodes: [UInt8] = []
    let bytecodeName = "mergedBytecodes"

    images.forEach { image in
      let bytecode = generateRouteBytecode(route: image.route)

      imagePossitions.append((mergedBytecodes.count, mergedBytecodes.count + bytecode.count - 1))
      mergedBytecodes += bytecode
    }

    let compressedBytecode = try compressBytecode(mergedBytecodes)
    let bytecodeString = """
    static const uint8_t \(bytecodeName)[] = {
      \(compressedBytecode.map(\.description).joined(separator: ", "))
    };
    """

    return (bytecodeString, imagePossitions, mergedBytecodes.count, compressedBytecode.count)
  }
}

@available(macOS 10.15, *)
func compressBytecode(_ bytecode: [UInt8]) throws -> [UInt8] {
  let pageSize = 128
  let sourceData = Data(bytecode)
  var compressedData = Data()

  let outputFilter = try OutputFilter(
   .compress,
   using: .lzfse,
   writingTo: { (data: Data?) -> Void in
     if let data {
       compressedData.append(data)
     }
   }
  )

  var index = 0
  let bufferSize = sourceData.count

  while true {
   let rangeLength = min(pageSize, bufferSize - index)

   let subdata = sourceData.subdata(in: index ..< index + rangeLength)
   index += rangeLength

   try outputFilter.write(subdata)

   if (rangeLength == 0) { break }
  }
  return [UInt8](compressedData)
}
