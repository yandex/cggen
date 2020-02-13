// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

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

  var cggenSupportHeaderBody: ObjcTerm {
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
) -> ObjcTerm {
  ObjcTerm(
    commonHeaderPrefix,
    .newLine,
    .import(.coreGraphics, .coreFoundation),
    .newLine,
    .inCFNonnullRegion(
      .swiftNamespace("\(module)Resources", cPref: prefix),
      .cdecl(.init(
        specifiers: [
          .storage(.typedef),
          .type(.structOrUnion(
            .struct, attributes: [], identifier: nil, declList: [
              .init(spec: [.simple(.CGSize)], decl: [.identifier("size")]),
              .init(spec: [.simple(.void)], decl: [.functionPointer(name: "drawingHandler", .type(.simple(.CGContextRef)))]),
            ]
          )),
        ], declarators: [
          .decl(.namedInSwift("\(module)Resources.Descriptor", decl: .identifier(descriptorTypeName))),
        ]
      ))
    ),
    .newLine
  )
}
