// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

enum ObjCGen {
  static func functionName(imageName: String, prefix: String) -> String {
    return "\(prefix)Draw\(imageName)ImageInContext"
  }

  static func functionWithArgs(imageName: String, prefix: String) -> String {
    return "void "
      .appending(functionName(imageName: imageName, prefix: prefix))
      .appending("(CGContextRef context)")
  }

  static func functionDecl(imageName: String, prefix: String) -> String {
    return functionWithArgs(imageName: imageName, prefix: prefix).appending(";")
  }

  static func functionDef(imageName: String, prefix: String) -> String {
    return functionWithArgs(imageName: imageName, prefix: prefix).appending(" {")
  }

  static func cgFloatArray(_ array: [CGFloat]) -> String {
    let elements = array.map { "(CGFloat)\($0)" }.joined(separator: ", ")
    return "(CGFloat []){\(elements)}"
  }
}

extension GenerationParams {
  var descriptorTypename: String {
    return prefix + module + "GeneratedImageDescriptor"
  }

  func descriptorName(for image: Image) -> String {
    return "k" + prefix + module + image.name.upperCamelCase + "Descriptor"
  }

  func moduleImport(_ name: String) -> String {
    if importAsModules {
      return "@import \(name);"
    } else {
      return "#import <\(name)/\(name).h>"
    }
  }

  var cggenSupportHeaderBody: String {
    return
      """
      \(commonHeaderPrefix)

      \(moduleImport("CoreFoundation"))
      \(moduleImport("CoreGraphics"))

      CF_ASSUME_NONNULL_BEGIN

      typedef struct CF_BRIDGED_TYPE(id) \(prefix)\(module)GraphicResources *\(prefix)\(module)GraphicResourcesRef
      CF_SWIFT_NAME(\(module)Resources);

      typedef struct {
      CGSize size;
      void (*drawingHandler)(CGContextRef);
      } \(descriptorTypename) CF_SWIFT_NAME(\(module)Resources.Descriptor);

      CF_ASSUME_NONNULL_END

      """
  }
}
