import CoreGraphics

import Base
import PDFParse

struct ObjcCGGenerator: CoreGraphicsGenerator {
  let params: GenerationParams
  let headerImportPath: String?

  func filePreamble() -> String {
    ObjcTerm([
      .hasFeatureSupport,
      headerImportPath.map { ObjcTerm.quotedImport($0) },
      .import(.coreGraphics),
      .newLine,
    ].compactMap(identity).insertSeparator(.newLine)).renderText()
  }

  func generateImageFunction(image: Image) -> String {
    var lines: [String] = []
    lines += funcStart(imageName: image.name)
    lines += functionBodyForDrawRoute(
      route: image.route,
      contextName: "context"
    )
    lines += [
      "  CGColorSpaceRelease(\(rgbColorSpaceVarName));",
      "}",
    ]
    lines += params.descriptorLines(for: image)

    return lines.joined(separator: "\n")
  }

  func fileEnding() -> String {
    ""
  }
}

private func functionBodyForDrawRoute(
  route: DrawRoute,
  contextName: String
) -> [String] {
  let subroutes = route.subroutes
    .flatMap { (key: String, route: DrawRoute) -> [String] in
      let contextName = "context_\(acquireUniqID())"
      let blockName = subrouteBlockName(subrouteName: key)
      let blockStart =
        "void (^\(blockName))(CGContextRef) = ^(CGContextRef \(contextName)) {"
      let blockEnd = "};"
      let commandsLines = functionBodyForDrawRoute(
        route: route,
        contextName: contextName
      )
      return ([blockStart] + commandsLines + [blockEnd]).map { "  \($0)" }
    }
  let generator = DrawStepToObjcCommandGenerator(
    uniqIDProvider: acquireUniqID,
    contextVarName: contextName,
    globalDeviceRGBContextName: rgbColorSpaceVarName,
    gDeviceRgbContext: .identifier(rgbColorSpaceVarName)
  )
  let commandsLines = route.steps.compactMap { (step) -> ObjcTerm.Statement? in
    generator.command(
      step: step,
      gradients: route.gradients,
      subroutes: route.subroutes
    )
  }
  return subroutes + commandsLines.render().flatMap(identity)
}

extension ObjcCGGenerator {
  private func funcStart(imageName: String) -> [String] {
    [
      params.style.drawingHandlerPrefix + ObjCGen.functionDef(
        imageName: imageName.upperCamelCase,
        prefix: params.prefix
      ),
      "  CGColorSpaceRef \(rgbColorSpaceVarName) = CGColorSpaceCreateDeviceRGB();",
      "  CGContextSetFillColorSpace(context, \(rgbColorSpaceVarName));",
      "  CGContextSetStrokeColorSpace(context, \(rgbColorSpaceVarName));",
    ]
  }
}

extension GenerationParams.Style {
  fileprivate var drawingHandlerPrefix: String {
    switch self {
    case .plain:
      return ""
    case .swiftFriendly:
      return "static "
    }
  }
}

extension GenerationParams {
  private func funcName(imageName: String) -> String {
    ObjCGen.functionName(imageName: imageName.upperCamelCase, prefix: prefix)
  }

  fileprivate func descriptorLines(for image: Image) -> [String] {
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

func subrouteBlockName(subrouteName: String) -> String {
  "subrouteNamed\(subrouteName)"
}

private var uniqColorID = 0
private func acquireUniqID() -> String {
  let uid = uniqColorID
  uniqColorID += 1
  return "\(uid)"
}

private let rgbColorSpaceVarName = "rgbColorSpace"
