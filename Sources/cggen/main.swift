import ArgumentParser
import Foundation

import CGGenCLI

extension GenerationStyle: ExpressibleByArgument {}

struct Main: ParsableCommand {
  @Option var objcHeader: String?
  @Option var objcPrefix = ""
  @Option var objcImpl: String?
  @Option var bytecodeFilePrefix: String?
  @Option var objcHeaderImportPath: String?
  @Option(help: "Interface generation style, swift-friendly or plain")
  var generationStyle: GenerationStyle = .plain
  @Option var cggenSupportHeaderPath: String?
  @Option var moduleName = ""
  @Option var swiftOutput: String?
  @Flag var verbose = false
  @Argument var files: [String]

  static let configuration = CommandConfiguration(
    commandName: "cggen",
    abstract: "Tool for generating Core Graphics code from SVG and PDF files",
    version: "1.0.0"
  )

  func run() throws {
    try runCggen(with: Args(
      objcHeader: objcHeader,
      objcPrefix: objcPrefix,
      objcImpl: objcImpl,
      objcHeaderImportPath: objcHeaderImportPath,
      generationStyle: generationStyle,
      cggenSupportHeaderPath: cggenSupportHeaderPath,
      module: moduleName,
      verbose: verbose,
      files: files,
      swiftOutput: swiftOutput
    ))
  }
}

Main.main()
