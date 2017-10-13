//
//  CoreGraphicsGen.swift
//  cggenPackageDescription
//
//  Created by Alfred Zien on 12/10/2017.
//

import Foundation

protocol CoreGraphicsCommandProvider {
  func preamble(imageName: String, imageSize: CGSize) -> [String]
  func command(step: DrawStep) -> [String]
  func conclusion(imageName: String, imageSize: CGSize) -> [String]
}

struct ObjCCGCommandProvider: CoreGraphicsCommandProvider {
  let prefix: String
  let rgbColorSpaceVarName = "rgbColorSpace"
  func cmd(_ name: String, _ args: String? = nil) -> String {
    let argStr: String
    if let args = args {
      argStr = ", \(args)"
    } else {
      argStr = ""
    }
    return "  CGContext\(name)(context\(argStr));"
  }
  func cmd(_ name: String, points: [CGPoint]) -> String {
    return cmd(name, points.map {"(CGFloat)\($0.x), (CGFloat)\($0.y)"}.joined(separator: ", ") )
  }
  func cmd(_ name: String, rect: CGRect) -> String {
    return cmd(name, "CGRectMake((CGFloat)\(rect.x), (CGFloat)\(rect.y), (CGFloat)\(rect.width), (CGFloat)\(rect.height))" )
  }
  func cmd(_ name: String, float: CGFloat) -> String {
    return cmd(name, "(CGFloat)\(float)")
  }
  static var uniqColorID = 0
  private static func asquireUniqColorID() -> Int {
    let uid = uniqColorID
    uniqColorID += 1
    return uid
  }
  func cmd(_ name: String, color: RGBColor) -> [String] {
    let colorVarName = "color\(ObjCCGCommandProvider.asquireUniqColorID())"
    let createColor = "  CGColorRef \(colorVarName) = CGColorCreate(\(rgbColorSpaceVarName), (CGFloat []){(CGFloat)\(color.red), (CGFloat)\(color.green), (CGFloat)\(color.blue), 1});"
    let cmdStr = cmd(name, "\(colorVarName)")
    let release = "  CGColorRelease(\(colorVarName));"
    return [createColor, cmdStr, release];
  }
  func command(step: DrawStep) -> [String] {
    switch step {
    case .saveGState:
      return [cmd("SaveGState")]
    case .restoreGState:
      return [cmd("RestoreGState")]
    case .moveTo(let p):
      return [cmd("MoveToPoint", points: [p])]
    case .curve(let c1, let c2, let end):
      return [cmd("AddCurveToPoint", points: [c1, c2, end])]
    case .line(let p):
      return [cmd("AddLineToPoint", points: [p])]
    case .closePath:
      return [cmd("ClosePath")]
    case .clip(let rule):
      switch rule {
      case .winding:
        return [cmd("Clip")]
      case .evenOdd:
        return [cmd("EOClip")]
      }
    case .endPath:
      return []
    case .flatness(let flatness):
      return [cmd("SetFlatness", float: flatness)]
    case .nonStrokeColorSpace:
      return []
    case .nonStrokeColor(let color):
      return cmd("SetFillColorWithColor", color: color)
    case .appendRectangle(let rect):
      return [cmd("AddRect", rect: rect)]
    case .fill(let rule):
      switch rule {
      case .winding:
        return [cmd("FillPath")]
      case .evenOdd:
        return [cmd("EOFillPath")]
      }
    }
  }

  func preamble(imageName: String, imageSize: CGSize) -> [String] {
    return [
      "void \(prefix)Draw\(imageName)ImageInContext(CGContextRef context) {",
      "  CGColorSpaceRef \(rgbColorSpaceVarName) = CGColorSpaceCreateDeviceRGB();" ]
  }
  func conclusion(imageName: String, imageSize: CGSize) -> [String] {
    return [ "  CGColorSpaceRelease(\(rgbColorSpaceVarName));", "}" ]
  }
}

struct ObjCCGCommandProviderHeader: CoreGraphicsCommandProvider {
  let prefix: String
  func command(step: DrawStep) -> [String] {
    return []
  }
  func preamble(imageName: String, imageSize: CGSize) -> [String] {
    return [
      "static const CGSize k\(imageName)ImageSize = (CGSize){.width = \(imageSize.width), .height = \(imageSize.height)};",
      "void \(prefix)Draw\(imageName)ImageInContext(CGContextRef context);",
    ]
  }
  func conclusion(imageName: String, imageSize: CGSize) -> [String] {
    return []
  }
}

extension DrawRoute {
  func genCGCode(imageName: String, commands: CoreGraphicsCommandProvider) -> String {
    let preambule = commands.preamble(imageName: imageName, imageSize: boundingRect.size)
    let commandsLines = getSteps().flatMap { commands.command(step: $0) }
    let conclusion = commands.conclusion(imageName: imageName, imageSize: boundingRect.size)
    return (preambule + commandsLines + conclusion).joined(separator: "\n")
  }
}
