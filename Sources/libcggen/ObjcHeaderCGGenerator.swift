import CoreGraphics

struct ObjcHeaderCGGenerator: CoreGraphicsGenerator {
  let params: GenerationParams
  let outputs: [Output]

  init(params: GenerationParams, outputs: [Output]) {
    self.params = params
    self.outputs = outputs
  }

  func filePreamble() -> String {
    params.imports.renderText() + "\n"
  }

  func generateImageFunctions() throws -> String {
    outputs.map(\.image).map { params.description(for: $0) }
      .joined(separator: "\n\n")
  }

  func generatePathFunctions() throws -> String {
    outputs.flatMap(\.pathRoutines).map { params.description(for: $0) }
      .joined(separator: "\n\n")
  }

  func fileEnding() throws -> String {
    ""
  }
}

extension GenerationParams {
  fileprivate var imports: ObjcTerm {
    switch style {
    case .plain:
      .import(.coreGraphics)
    case .swiftFriendly:
      .preprocessorDirective(
        .import(.doubleQuotes(path: "cggen_support.h"))
      )
    }
  }
}

extension GenerationParams {
  fileprivate func description(for image: Image) -> String {
    let camel = image.name.upperCamelCase
    let imageSize = image.route.boundingRect.size

    switch style {
    case .plain:
      let functionDecl = ObjCGen.functionDecl(imageName: camel, prefix: prefix)
      return
        """
        static const CGSize k\(prefix)\(camel)ImageSize = (CGSize){.width = \(
          imageSize
            .width
        ), .height = \(imageSize.height)};
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

  fileprivate func description(for path: PathRoutine) -> String {
    let camel = path.id.upperCamelCase
    return "void \(prefix)\(camel)Path(CGMutablePathRef path);"
  }
}
