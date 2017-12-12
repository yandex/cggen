//
//  ObjCGen.swift
//  cggenPackageDescription
//
//  Created by Alfred Zien on 25/11/2017.
//

import Foundation

struct ObjCGen {
  private init() {
  }
  static func functionName(imageName: String, prefix: String) -> String {
    return "\(prefix)Draw\(imageName)ImageInContext"
  }
  static func functionWithArgs(imageName: String, prefix: String) -> String {
    return "void "
      .appending(functionName(imageName:imageName, prefix:prefix))
      .appending("(CGContextRef context)")
  }
  static func functionDecl(imageName: String, prefix: String) -> String {
    return functionWithArgs(imageName:imageName, prefix:prefix).appending(";")
  }
  static func functionDef(imageName: String, prefix: String) -> String {
    return functionWithArgs(imageName:imageName, prefix:prefix).appending(" {")
  }
}
