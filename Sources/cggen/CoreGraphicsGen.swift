// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

struct ImageName {
  let snakeCase: String
  let camelCase: String
  init(snakeCase: String) {
    self.snakeCase = snakeCase
    camelCase = snakeCase.snakeToCamelCase()
  }
}

protocol CoreGraphicsGenerator {
  func filePreamble() -> String
  func funcStart(imageName: ImageName, imageSize: CGSize) -> [String]
  func command(step: DrawStep, gradients: [String: Gradient]) -> [String]
  func funcEnd(imageName: ImageName, imageSize: CGSize) -> [String]
  func fileEnding() -> String
}

extension CoreGraphicsGenerator {
  private func generateImageFunction(imgName: ImageName, route: DrawRoute) -> [String] {
    let size = route.boundingRect.size
    let preambleLines = funcStart(imageName: imgName, imageSize: size)
    let commandsLines = route.steps.flatMap {
      command(step: $0,
              gradients: route.gradients)
    }
    let conclusionLines = funcEnd(imageName: imgName, imageSize: size)
    return preambleLines + commandsLines + conclusionLines
  }

  private func generateImageFunction(nameAndRoute: (ImageName, DrawRoute)) -> String {
    return generateImageFunction(imgName: nameAndRoute.0, route: nameAndRoute.1).joined(separator: "\n")
  }

  func generateFile(namesAndRoutes: [(ImageName, DrawRoute)]) -> String {
    return filePreamble()
      + namesAndRoutes.map({ generateImageFunction(nameAndRoute: $0) }).joined(separator: "\n\n")
      + "\n"
      + fileEnding()
      + "\n"
  }
}
