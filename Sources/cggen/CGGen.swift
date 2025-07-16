import ArgumentParser
import Foundation

import CGGenCLI
import CGGenCore

extension GenerationStyle: ExpressibleByArgument {}

struct CGGen: ParsableCommand {
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

@main
struct Main {
  static func main() {
    SignalHandling.intercepting(.bus, .segmentationFault) {
      CGGen.main()
    } onSignal: { signal in
      print("\(signal.name) received!")
      print("Working directory: \(FileManager.default.currentDirectoryPath)")
      print("Command line: \(CommandLine.arguments.joined(separator: " "))")
      print("\nStack trace:")
      Thread.callStackSymbols.forEach { print($0) }
      fflush(stdout)
    }
  }
}
