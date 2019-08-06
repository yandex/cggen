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

  var cggenSupportHeaderBody: ObjcTerm {
    return supportHeader(
      importAsModules: importAsModules, prefix: prefix, module: module
    )
  }
}

private func supportHeader(
  importAsModules: Bool,
  prefix: String,
  module: String
) -> ObjcTerm {
  return ObjcTerm(
    commonHeaderPrefix,
    .newLine,
    .import(.coreGraphics, .coreFoundation, asModule: importAsModules),
    .newLine,
    .inCFNonnullRegion(
      .swiftNamespace("\(module)Resources", cPref: prefix),
      .cdecl(.init(
        specifiers: [
          .storage(.typedef),
          .type(.structOrUnion(
            .struct, attributes: [], identifier: nil, declList: [
              .init(spec: [.CGSize], decl: [.identifier("size")]),
              .init(spec: [.void], decl: [.functionPointer(name: "drawingHandler", .type(.CGContextRef))]),
            ]
          )),
        ], declarators: [
          .namedInSwift("\(module)Resources.Descriptor", decl: .identifier("descriptorTypename")),
        ]
      ))
    )
  )
}
