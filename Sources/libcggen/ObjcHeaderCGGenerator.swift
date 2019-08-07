// Copyright (c) 2018 Yandex LLC. All rights reserved.
// Author: Alexander Skvortsov <askvortsov@yandex-team.ru>

import CoreGraphics

struct ObjcHeaderCGGenerator: CoreGraphicsGenerator {
  let params: GenerationParams
  func filePreamble() -> String {
    return params.imports.renderText() + "\n"
  }

  func generateImageFunction(image: Image) -> String {
    return params.description(for: image)
  }

  func fileEnding() -> String {
    return ""
  }
}

private extension GenerationParams {
  var imports: ObjcTerm {
    switch style {
    case .plain:
      return .import(.coreGraphics, asModule: importAsModules)
    case .swiftFriendly:
      return .import(.doubleQuotes(path: "cggen_support.h"))
    }
  }
}

private extension GenerationParams {
  func description(for image: Image) -> String {
    let camel = image.name.upperCamelCase
    let imageSize = image.route.boundingRect.size

    switch style {
    case .plain:
      let functionDecl = ObjCGen.functionDecl(imageName: camel, prefix: prefix)
      return
        """
        static const CGSize k\(prefix)\(camel)ImageSize = (CGSize){.width = \(imageSize.width), .height = \(imageSize.height)};
        \(functionDecl)
        """
    case .swiftFriendly:
      let descriptorVarName = descriptorName(for: image)
      return
        """
        extern const \(descriptorTypename) \(descriptorVarName)
        CF_SWIFT_NAME(\(descriptorTypename).\(image.name.lowerCamelCase));
        """
    }
  }
}
