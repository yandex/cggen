// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

protocol CoreGraphicsGenerator {
  func filePreamble() -> String
  func generateImageFunction(image: Image) -> String
  func fileEnding() -> String
}

extension CoreGraphicsGenerator {
  func generateFile(images: [Image]) -> String {
    return filePreamble()
      + images.map(generateImageFunction).joined(separator: "\n\n")
      + "\n"
      + fileEnding()
      + "\n"
  }
}
