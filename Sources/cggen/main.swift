import ArgumentParser
import Base
import Foundation
import libcggen

struct Main: ParsableCommand {
  @Option var objcHeader: String?
  @Option var objcPrefix = ""
  @Option var objcImpl: String?
  @Option var objcHeaderImportPath: String?
  @Option var objcCallerPath: String?
  @Option var callerScale = 1.0
  @Option var callerPngOutput: String?
  @Option var generationStyle: String?
  @Option var cggenSupportHeaderPath: String?
  @Option var moduleName = ""
  @Flag var verbose = false
  @Argument var files: [String]

  static let configuration = CommandConfiguration(
    commandName: "cggen",
    abstract: "Tool for generationg CoreGraphics code from vector images in pdf format",
    version: "0.1"
  )

  public mutating func run() throws {
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
      files: files
    )
    )
  }
}

Main.main()
