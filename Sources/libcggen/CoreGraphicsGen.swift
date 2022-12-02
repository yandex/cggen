import Foundation

import Base

protocol CoreGraphicsGenerator {
  func filePreamble() -> String
  func generateImageFunction(image: Image) -> String
  func generatePathFuncton(path: PathRoutine) -> String
  func fileEnding() -> String
}

extension CoreGraphicsGenerator {
  func generateFile(outputs: [Output]) -> String {
    let imageFunctions = outputs.map { generateImageFunction(image: $0.image) }
      .joined(separator: "\n\n")
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
