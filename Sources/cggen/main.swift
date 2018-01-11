// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import ArgParse
import Base
import Foundation
import PDFParse

struct Args {
  let objcHeader: String?
  let objcPrefix: String?
  let objcImpl: String?
  let objcHeaderImportPath: String?
  let objcCallerPath: String?
  let callerScale: Double
  let callerPngOutputPath: String?
  let verbose: Bool
  let files: [String]
}

func parseArgs() -> Args {
  let parser = ArgParser(helptext: "Tool for generationg CoreGraphics code from vector images in pdf format",
                         version: "0.1")
  let objcHeaderKey = "objc-header"
  let objcPrefixKey = "objc-prefix"
  let objcImplKey = "objc-impl"
  let objcHeaderImportPathKey = "objc-header-import-path"
  let objcCallerPathKey = "objc-caller-path"
  let callerScaleKey = "caller-scale"
  let callerPngOutputPathKey = "caller-png-output"
  let verboseFlagKey = "verbose"
  parser.newString(objcHeaderKey)
  parser.newString(objcImplKey)
  parser.newString(objcHeaderImportPathKey)
  parser.newString(objcPrefixKey)
  parser.newString(objcCallerPathKey)
  parser.newDouble(callerScaleKey)
  parser.newString(callerPngOutputPathKey)
  parser.newFlag(verboseFlagKey)
  parser.parse()
  return Args(objcHeader: parser.string(at: objcHeaderKey),
              objcPrefix: parser.string(at: objcPrefixKey),
              objcImpl: parser.string(at: objcImplKey),
              objcHeaderImportPath: parser.string(at: objcHeaderImportPathKey),
              objcCallerPath: parser.string(at: objcCallerPathKey),
              callerScale: parser.double(at: callerScaleKey) ?? 1,
              callerPngOutputPath: parser.string(at: callerPngOutputPathKey),
              verbose: parser.getFlag(verboseFlagKey),
              files: parser.getArgs())
}

func main(args: Args) {
  Logger.shared.setLevel(level: args.verbose)
  var stopwatch = StopWatch()

  let images = args.files
    .map { URL(fileURLWithPath: $0) }
    .concurrentMap { ($0.deletingPathExtension().lastPathComponent,
                      PDFParser.parse(pdfURL: $0 as CFURL)) }
    .flatMap { nameAndRoutes in
      nameAndRoutes.1.enumerated().flatMap { (offset, route) -> Image in
        let finalName = nameAndRoutes.0 + (offset == 0 ? "" : "_\(offset)")
        let imgName = Image.Name(snakeCase: finalName)
        return Image(name: imgName, route: route)
      }
    }
  log("Parsed in: \(stopwatch.reset())")
  let objcPrefix = args.objcPrefix ?? ""

  if let objcHeaderPath = args.objcHeader {
    let headerGenerator = ObjcHeaderCGGenerator(prefix: objcPrefix)
    let fileStr = headerGenerator.generateFile(images: images)
    try! fileStr.write(toFile: objcHeaderPath, atomically: true, encoding: .utf8)
  }
  log("Header generated in: \(stopwatch.reset())")

  if let objcImplPath = args.objcImpl {
    let headerImportPath = args.objcHeaderImportPath
    let implGenerator = ObjcCGGenerator(prefix: objcPrefix,
                                        headerImportPath: headerImportPath)
    let fileStr = implGenerator.generateFile(images: images)
    try! fileStr.write(toFile: objcImplPath, atomically: true, encoding: .utf8)
  }
  log("Impl generated in: \(stopwatch.reset())")

  if let objcCallerPath = args.objcCallerPath,
    let pngOutputPath = args.callerPngOutputPath,
    let headerImportPath = args.objcHeaderImportPath {
    let callerGenerator = ObjcCallerGen(headerImportPath: headerImportPath,
                                        scale: args.callerScale.cgfloat,
                                        prefix: objcPrefix,
                                        outputPath: pngOutputPath)
    let fileStr = callerGenerator.generateFile(images: images)
    try! fileStr.write(toFile: objcCallerPath, atomically: true, encoding: .utf8)
  }

  log("Caller generated in: \(stopwatch.reset())")
}

main(args: parseArgs())
