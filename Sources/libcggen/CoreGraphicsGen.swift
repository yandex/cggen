import Foundation

import Base

protocol CoreGraphicsGenerator {
  func filePreamble() -> String
  func generateImageFunctions(images: [Image]) throws -> String
  func generatePathFuncton(path: PathRoutine) -> String
  func fileEnding() -> String
}

extension CoreGraphicsGenerator {
  func generateFile(outputs: [Output]) throws -> String {
    let imageFunctions = try generateImageFunctions(images: outputs.map(\.image))
    let pathFunctions = outputs.flatMap(\.pathRoutines).map(generatePathFuncton)
      .joined(separator: "\n\n")
    return
      """
      \(commonHeaderPrefix.renderText())

      \(filePreamble())

      \(imageFunctions)

      \(pathFunctions)

      \(fileEnding())

      """
  }
}
