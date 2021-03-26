import CoreGraphics

public struct ObjcHeaderCGGenerator: CoreGraphicsGenerator {
  let params: GenerationParams

  public init(params: GenerationParams) {
    self.params = params
  }

  public func filePreamble() -> String {
    params.imports.renderText() + "\n"
  }

  public func generateImageFunction(image: Image) -> String {
    params.description(for: image)
  }

  public func fileEnding() -> String {
    ""
  }
}

private extension GenerationParams {
  var imports: ObjcTerm {
    switch style {
    case .plain:
      return .import(.coreGraphics)
    case .swiftFriendly:
      return .preprocessorDirective(.import(.doubleQuotes(path: "cggen_support.h")))
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
