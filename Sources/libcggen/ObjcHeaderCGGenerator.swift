import CGGen
import CoreGraphics

func generateObjCHeaderFile(
  params: GenerationParams,
  outputs: [Output]
) -> String {
  var result = ""

  // Header comment
  result += commonHeaderPrefix + "\n\n"

  // Imports
  result += params.imports + "\n\n"

  // Image functions
  let imageFunctions = outputs.map(\.image)
    .map { params.description(for: $0) }
    .joined(separator: "\n\n")
  if !imageFunctions.isEmpty {
    result += imageFunctions + "\n\n"
  }

  // Path functions
  let pathFunctions = outputs.flatMap(\.pathRoutines)
    .map { params.description(for: $0) }
    .joined(separator: "\n\n")
  if !pathFunctions.isEmpty {
    result += pathFunctions + "\n\n"
  }

  return result
}

extension GenerationParams {
  fileprivate var imports: String {
    switch style {
    case .plain:
      """
      #if __has_feature(modules)
      @import CoreGraphics;
      #else  // __has_feature(modules)
      #import <CoreGraphics/CoreGraphics.h>
      #endif  // __has_feature(modules)
      """
    case .swiftFriendly:
      "#import \"cggen_support.h\""
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
