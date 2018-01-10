//
//  ObjCGen.swift
//  cggenPackageDescription
//
//  Created by Alfred Zien on 25/11/2017.
//

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
