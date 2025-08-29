import ArgumentParser
import Foundation

@main
struct CGGenDiagnostic: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "cggen-diagnostic",
    abstract: "Diagnostic tools for cggen",
    subcommands: [RenderCompareCommand.self, DecodeCommand.self]
  )
}
