import Foundation

enum ObjCGen {
  static func functionName(imageName: String, prefix: String) -> String {
    "\(prefix)Draw\(imageName)ImageInContext"
  }

  static func functionWithArgs(imageName: String, prefix: String) -> String {
    "void "
      .appending(functionName(imageName: imageName, prefix: prefix))
      .appending("(CGContextRef context)")
  }

  static func functionDecl(imageName: String, prefix: String) -> String {
    functionWithArgs(imageName: imageName, prefix: prefix).appending(";")
  }

  static func functionDef(imageName: String, prefix: String) -> String {
    functionWithArgs(imageName: imageName, prefix: prefix).appending(" {")
  }

  static func cgFloatArray(_ array: [CGFloat]) -> String {
    let elements = array.map { "(CGFloat)\($0)" }.joined(separator: ", ")
    return "(CGFloat []){\(elements)}"
  }
}

extension GenerationParams {
  var descriptorTypename: String {
    prefix + module + "GeneratedImageDescriptor"
  }

  func descriptorName(for image: Image) -> String {
    "k" + prefix + module + image.name.upperCamelCase + "Descriptor"
  }

  var cggenSupportHeaderBody: String {
    supportHeader(
      prefix: prefix,
      module: module,
      descriptorTypeName: descriptorTypename
    )
  }
}

private func supportHeader(
  prefix: String,
  module: String,
  descriptorTypeName: String
) -> String {
  """
  \(commonHeaderPrefix)

  #if __has_feature(modules)
  @import CoreGraphics;
  @import CoreFoundation;
  #else
  #import <CoreGraphics/CoreGraphics.h>
  #import <CoreFoundation/CoreFoundation.h>
  #endif

  CF_ASSUME_NONNULL_BEGIN

  typedef struct CF_BRIDGED_TYPE(id) \(prefix)\(module)Resources *\(prefix)\(
    module
  )ResourcesRef CF_SWIFT_NAME(\(module)Resources);

  typedef struct {
    CGSize size;
    void (*drawingHandler)(CGContextRef);
  } \(descriptorTypeName) CF_SWIFT_NAME(\(module)Resources.Descriptor);

  CF_ASSUME_NONNULL_END

  """
}
