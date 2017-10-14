// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation
import ArgParse


extension ArgParser {
  func string(at key: String) -> String? {
    return parser.found(key) ? parser.getString(key) : nil
  }
}

let parser = ArgParser(helptext: "Tool for generationg CoreGraphics code from vector images in pdf format",
                       version: "0.1")

let objcHeaderKey = "objc-header"
let objcPrefixKey = "objc-prefix"
let objcImplKey = "objc-impl"
let objcHeaderImportPathKey = "objc-header-import-path"
parser.newString(objcHeaderKey)
parser.newString(objcImplKey)
parser.newString(objcHeaderImportPathKey)
parser.newString(objcPrefixKey)
parser.parse()

let objcHeaderArg = parser.found(objcHeaderKey) ?
  parser.getString(objcHeaderKey) : nil

let routes = parser.getArgs()
  .map { URL(fileURLWithPath: $0) }
  .map { ($0.deletingPathExtension().lastPathComponent, parse(pdfURL: $0 as CFURL)) }
  .flatMap { (nameAndRoutes) in
    nameAndRoutes.1.enumerated().flatMap({ (offset, route) -> (String, DrawRoute) in
      let finalName = nameAndRoutes.0 + (offset == 0 ? "" : "_\(offset)")
      return (finalName.snakeToCamelCase(), route)
    })
}

let objcPrefix = parser.string(at: objcPrefixKey) ?? ""

if let objcHeaderPath = parser.string(at: objcHeaderKey) {
  let headerGenerator = ObjcHeaderCGGenerator(prefix: objcPrefix)
  let fileStr = headerGenerator.generateFile(namesAndRoutes: routes)
  try! fileStr.write(toFile: objcHeaderPath, atomically: true, encoding: .utf8)
}

if let objcImplPath = parser.string(at: objcImplKey) {
  let headerPath = parser.string(at: objcHeaderImportPathKey)
  let implGenerator = ObjcCGGenerator(prefix: objcPrefix,
                                      headerImportPath: headerPath)
  let fileStr = implGenerator.generateFile(namesAndRoutes: routes)
  try! fileStr.write(toFile: objcImplPath, atomically: true, encoding: .utf8)
}
