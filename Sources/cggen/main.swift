import ArgumentParser
import Foundation

import libcggen

extension GenerationStyle: ExpressibleByArgument {}

struct Main: ParsableCommand {
  @Option var objcHeader: String?
  @Option var objcPrefix = ""
  @Option var objcImpl: String?
  @Option var bytecodeFilePrefix: String?
  @Option var objcHeaderImportPath: String?
  @Option var objcCallerPath: String?
  @Option var callerScale = 1.0
  @Option var callerPngOutput: String?
  @Option(help: "Interface generation style, swift-friendly or plain")
  var generationStyle: GenerationStyle = .plain
  @Option var cggenSupportHeaderPath: String?
  @Option var moduleName = ""
  @Flag var verbose = false
  @Argument var files: [String]
  @Flag var shouldMergeBytecode = false

  static let configuration = CommandConfiguration(
    commandName: "cggen",
    abstract: "Tool for generationg CoreGraphics code from vector images in pdf format",
    version: "0.1"
  )

  func run() throws {
    try runCggen(with: Args(
      objcHeader: objcHeader,
      objcPrefix: objcPrefix,
      objcImpl: objcImpl,
      objcHeaderImportPath: objcHeaderImportPath,
      objcCallerPath: objcCallerPath,
      callerScale: callerScale,
      callerPngOutputPath: callerPngOutput,
      generationStyle: generationStyle,
      cggenSupportHeaderPath: cggenSupportHeaderPath,
      module: moduleName,
      verbose: verbose,
      files: files,
      shouldMergeBytecode: shouldMergeBytecode
    ))
  }
}

Main.main()
