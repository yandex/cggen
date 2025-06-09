import Foundation

import Base

protocol CoreGraphicsGenerator {
  func filePreamble() -> String
  func generateImageFunctions() throws -> String
  func generatePathFunctions() throws -> String
  func fileEnding() throws -> String
}

extension CoreGraphicsGenerator {
  func generateFile() throws -> String {
    var sections = [String]()

    sections.append(commonHeaderPrefix.renderText())
    sections.append(filePreamble())
    try sections.append(generateImageFunctions())

    let pathFunctions = try generatePathFunctions()
    if !pathFunctions.isEmpty {
      sections.append(pathFunctions)
    }

    try sections.append(fileEnding())

    return sections.joined(separator: "\n\n") + "\n"
  }
}
