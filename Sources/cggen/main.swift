// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import ArgParse
import Foundation

extension Double {
  var cgfloat: CGFloat {
    return CGFloat(self)
  }
}

struct Args {
  let objcHeader: String?
  let objcPrefix: String?
  let objcImpl: String?
  let objcHeaderImportPath: String?
  let objcCallerPath: String?
  let callerScale: Double
  let callerPngOutputPath: String?
  let verbose: Bool
  let pngOutputDir: String?
  let files: [String]
}

func ParseArgs() -> Args {
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
  let pngOutputDirKey = "output-png"
  parser.newString(objcHeaderKey)
  parser.newString(objcImplKey)
  parser.newString(objcHeaderImportPathKey)
  parser.newString(objcPrefixKey)
  parser.newString(objcCallerPathKey)
  parser.newDouble(callerScaleKey)
  parser.newString(callerPngOutputPathKey)
  parser.newFlag(verboseFlagKey)
  parser.newString(pngOutputDirKey)
  parser.parse()
  return Args(objcHeader: parser.string(at: objcHeaderKey),
              objcPrefix: parser.string(at: objcPrefixKey),
              objcImpl: parser.string(at: objcImplKey),
              objcHeaderImportPath: parser.string(at: objcHeaderImportPathKey),
              objcCallerPath: parser.string(at: objcCallerPathKey),
              callerScale: parser.double(at: callerScaleKey) ?? 1,
              callerPngOutputPath: parser.string(at: callerPngOutputPathKey),
              verbose: parser.getFlag(verboseFlagKey),
              pngOutputDir: parser.getString(pngOutputDirKey),
              files: parser.getArgs())
}

func main(args: Args) {
  Logger.shared.setLevel(level: args.verbose)
  let routes = args.files
    .map { URL(fileURLWithPath: $0) }
    .concurrentMap { ($0.deletingPathExtension().lastPathComponent,
                      PDFParser.parse(pdfURL: $0 as CFURL)) }
    .flatMap { nameAndRoutes in
      nameAndRoutes.1.enumerated().flatMap { (offset, route) -> (ImageName, DrawRoute) in
        let finalName = nameAndRoutes.0 + (offset == 0 ? "" : "_\(offset)")
        let imgName = ImageName(snakeCase: finalName)
        return (imgName, route)
      }
    }

  let objcPrefix = args.objcPrefix ?? ""

  if let objcHeaderPath = args.objcHeader {
    let headerGenerator = ObjcHeaderCGGenerator(prefix: objcPrefix)
    let fileStr = headerGenerator.generateFile(namesAndRoutes: routes)
    try! fileStr.write(toFile: objcHeaderPath, atomically: true, encoding: .utf8)
  }

  if let objcImplPath = args.objcImpl {
    let headerImportPath = args.objcHeaderImportPath
    let implGenerator = ObjcCGGenerator(prefix: objcPrefix,
                                        headerImportPath: headerImportPath)
    let fileStr = implGenerator.generateFile(namesAndRoutes: routes)
    try! fileStr.write(toFile: objcImplPath, atomically: true, encoding: .utf8)
  }

  if let objcCallerPath = args.objcCallerPath,
    let pngOutputPath = args.callerPngOutputPath,
    let headerImportPath = args.objcHeaderImportPath {
    let callerGenerator = ObjcCallerGen(headerImportPath: headerImportPath,
                                        scale: args.callerScale.cgfloat,
                                        prefix: objcPrefix,
                                        outputPath: pngOutputPath)
    let fileStr = callerGenerator.generateFile(namesAndRoutes: routes)
    try! fileStr.write(toFile: objcCallerPath, atomically: true, encoding: .utf8)
  }

  if let pngOutputDir = args.pngOutputDir {
    args.files
      .map(URL.init(fileURLWithPath:))
      .map { ($0.deletingPathExtension().lastPathComponent, CGPDFDocument($0 as CFURL)!) }
      .flatMap { $0.1.pages.appendToAll(a: $0.0) }
      .map { ($0.0, $0.1.render(scale: args.callerScale.cgfloat)!) }
      .forEach { (name: String, img: CGImage) in
        let url = URL(fileURLWithPath: pngOutputDir)
          .appendingPathComponent("\(name).png") as CFURL
        try! img.write(fileURL: url) }
  }
}

main(args: ParseArgs())
