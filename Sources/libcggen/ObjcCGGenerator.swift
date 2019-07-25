// Copyright (c) 2018 Yandex LLC. All rights reserved.
// Author: Alexander Skvortsov <askvortsov@yandex-team.ru>

import Base
import CoreGraphics
import PDFParse

struct ObjcCGGenerator: CoreGraphicsGenerator {
  let params: GenerationParams
  let headerImportPath: String?

  func filePreamble() -> String {
    return ObjcTerm([
      headerImportPath.map { ObjcTerm.import(.doubleQuotes(path: $0)) },
      .import(.foundation, .coreGraphics, asModule: params.importAsModules),
    ].compactMap(identity).insertSeparator(.newLine)).renderText()
  }

  func generateImageFunction(image: Image) -> String {
    var lines: [String] = []
    lines += funcStart(imageName: image.name)
    lines += functionBodyForDrawRoute(route: image.route, contextName: "context")
    lines += [
      "  CGColorSpaceRelease(\(rgbColorSpaceVarName));",
      "}",
    ]
    lines += params.descriptorLines(for: image)

    return lines.joined(separator: "\n")
  }

  func fileEnding() -> String {
    return ""
  }
}

private func functionBodyForDrawRoute(route: DrawRoute, contextName: String) -> [String] {
  let subroutes = route.subroutes.flatMap { (key, route) -> [String] in
    let contextName = "context_\(acquireUniqID())"
    let blockName = subrouteBlockName(subrouteName: key)
    let blockStart = "void (^\(blockName))(CGContextRef) = ^(CGContextRef \(contextName)) {"
    let blockEnd = "};"
    let commandsLines = functionBodyForDrawRoute(route: route, contextName: contextName)
    return ([blockStart] + commandsLines + [blockEnd]).map { "  \($0)" }
  }
  let generator = DrawStepToObjcCommandGenerator(uniqIDProvider: acquireUniqID,
                                                 contextVarName: contextName,
                                                 globalDeviceRGBContextName: rgbColorSpaceVarName)
  let commandsLines = route.steps.flatMap { (step) -> [String] in
    generator.command(step: step,
                      gradients: route.gradients,
                      subroutes: route.subroutes)
  }
  return subroutes + commandsLines
}

extension ObjcCGGenerator {
  private func funcStart(imageName: String) -> [String] {
    return [
      params.style.drawingHandlerPrefix + ObjCGen.functionDef(imageName: imageName.upperCamelCase, prefix: params.prefix),
      "  CGColorSpaceRef \(rgbColorSpaceVarName) = CGColorSpaceCreateDeviceRGB();",
    ]
  }
}

private extension GenerationParams.Style {
  var drawingHandlerPrefix: String {
    switch self {
    case .plain:
      return ""
    case .swiftFriendly:
      return "static "
    }
  }
}

private extension GenerationParams {
  private func funcName(imageName: String) -> String {
    return ObjCGen.functionName(imageName: imageName.upperCamelCase, prefix: prefix)
  }

  func descriptorLines(for image: Image) -> [String] {
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

private func cmd(_ name: String, _ args: String? = nil) -> String {
  let argStr: String
  if let args = args {
    argStr = ", \(args)"
  } else {
    argStr = ""
  }
  return "  CGContext\(name)(context\(argStr));"
}

func subrouteBlockName(subrouteName: String) -> String {
  return "subrouteNamed\(subrouteName)"
}

private var uniqColorID = 0
private func acquireUniqID() -> String {
  let uid = uniqColorID
  uniqColorID += 1
  return "\(uid)"
}

private let rgbColorSpaceVarName = "rgbColorSpace"
