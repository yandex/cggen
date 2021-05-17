struct GenerationParams {
  let style: GenerationStyle
  let prefix: String
  let module: String
}

extension GenerationParams {
  private func funcName(imageName: String) -> String {
    ObjCGen.functionName(imageName: imageName.upperCamelCase, prefix: prefix)
  }

  internal func descriptorLines(for image: Image) -> [String] {
    switch style {
    case .plain:
      return []
    case .swiftFriendly:
      let size = image.route.boundingRect.size
      return [
        "const \(descriptorTypename) \(descriptorName(for: image)) = {",
        "  { (CGFloat)\(size.width), (CGFloat)\(size.height) },",
        "  \(funcName(imageName: image.name))",
        "};",
      ]
    }
  }
}

