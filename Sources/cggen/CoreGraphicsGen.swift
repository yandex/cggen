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
  func generateImageFunction(imgName: ImageName, route: DrawRoute) -> String
  func fileEnding() -> String
}

extension CoreGraphicsGenerator {
  private func generateImageFunction(nameAndRoute: (ImageName, DrawRoute)) -> String {
    return generateImageFunction(imgName: nameAndRoute.0, route: nameAndRoute.1)
  }

  func generateFile(namesAndRoutes: [(ImageName, DrawRoute)]) -> String {
    return filePreamble()
      + namesAndRoutes.map(generateImageFunction).joined(separator: "\n\n")
      + "\n"
      + fileEnding()
      + "\n"
  }
}
