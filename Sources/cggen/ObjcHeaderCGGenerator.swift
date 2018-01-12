// Copyright (c) 2018 Yandex LLC. All rights reserved.
// Author: Alexander Skvortsov <askvortsov@yandex-team.ru>

import CoreGraphics

struct ObjcHeaderCGGenerator: CoreGraphicsGenerator {
  let params: GenerationParams
  func filePreamble() -> String {
    return
      """
      \(params.imports)

      """
  }

  func generateImageFunction(image: Image) -> String {
    return params.description(for: image)
  }

  func fileEnding() -> String {
    return ""
  }
}

private extension GenerationParams {
  var imports: String {
    switch style {
    case .plain:
      return moduleImport("CoreGraphics")
    case .swiftFriendly:
      return "#include \"cggen_support.h\""
    }
  }
}

private extension GenerationParams {
  func description(for image: Image) -> String {
    let camel = image.name.upperCamelCase
    let imageSize = image.route.boundingRect.size

    switch style {
    case .plain:
      return
        """
        static const CGSize k\(prefix)\(camel)ImageSize = (CGSize){.width = \(imageSize.width), .height = \(imageSize.height)};
        \(ObjCGen.functionDecl(imageName: camel, prefix: prefix))
        """
    case .swiftFriendly:
      return
        """
        extern const \(descriptorTypename) \(descriptorName(for: image))
        CF_SWIFT_NAME(\(module)Resources.\(image.name.lowerCamelCase));
        """
    }
  }
}
