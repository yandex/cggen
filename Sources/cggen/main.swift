import Foundation

import ArgParse
import Base
import libcggen

func parseArgs() -> Args {
  let parser = ArgParser(
    helptext: "Tool for generationg CoreGraphics code from vector images in pdf format",
    version: "0.1"
  )
  let objcHeaderKey = "objc-header"
  let objcPrefixKey = "objc-prefix"
  let objcImplKey = "objc-impl"
  let objcHeaderImportPathKey = "objc-header-import-path"
  let objcCallerPathKey = "objc-caller-path"
  let callerScaleKey = "caller-scale"
  let callerPngOutputPathKey = "caller-png-output"
  let generationStyleKey = "generation-style"
  let cggenSupportHeaderPathKey = "cggen-support-header-path"
  let moduleKey = "module-name"
  let verboseFlagKey = "verbose"
  parser.newString(objcHeaderKey)
  parser.newString(objcImplKey)
  parser.newString(objcHeaderImportPathKey)
  parser.newString(objcPrefixKey)
  parser.newString(objcCallerPathKey)
  parser.newDouble(callerScaleKey)
  parser.newString(callerPngOutputPathKey)
  parser.newString(generationStyleKey)
  parser.newString(cggenSupportHeaderPathKey)
  parser.newString(moduleKey)
  parser.newFlag(verboseFlagKey)
  parser.parse()
  return Args(
    objcHeader: parser.string(at: objcHeaderKey),
    objcPrefix: parser.string(at: objcPrefixKey),
    objcImpl: parser.string(at: objcImplKey),
    objcHeaderImportPath: parser.string(at: objcHeaderImportPathKey),
    objcCallerPath: parser.string(at: objcCallerPathKey),
    callerScale: parser.double(at: callerScaleKey) ?? 1,
    callerPngOutputPath: parser.string(at: callerPngOutputPathKey),
    generationStyle: parser.string(at: generationStyleKey),
    cggenSupportHeaderPath: parser.string(at: cggenSupportHeaderPathKey),
    module: parser.string(at: moduleKey),
    verbose: parser.getFlag(verboseFlagKey),
    files: parser.getArgs()
  )
}

try runCggen(with: parseArgs())
