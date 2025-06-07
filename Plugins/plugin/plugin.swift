import Foundation
import PackagePlugin

@main
struct Plugin: BuildToolPlugin {
  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) async throws -> [Command] {
    guard let sourceTarget = target as? SourceModuleTarget else {
      return []
    }

    // Find all SVG and PDF files in the target's source directories
    let svgFiles = sourceTarget.sourceFiles(withSuffix: ".svg")
    let pdfFiles = sourceTarget.sourceFiles(withSuffix: ".pdf")
    let inputFiles = Array(svgFiles) + Array(pdfFiles)

    guard !inputFiles.isEmpty else {
      print("CggenPlugin: No SVG or PDF files found in \(target.name)")
      return []
    }

    print(
      "CggenPlugin: Found \(inputFiles.count) files in \(target.name): \(inputFiles.map { $0.url.lastPathComponent })"
    )

    // Create output directory for generated Swift files
    let outputDir = context.pluginWorkDirectoryURL.appending(path: "Generated")
    let outputFile = outputDir.appending(path: "\(target.name)_Generated.swift")

    // Get the cggen tool
    let cggenTool = try context.tool(named: "cggen")

    // Build command arguments
    var arguments: [String] = []

    // Add input files
    for file in inputFiles {
      arguments.append(file.url.path)
    }

    // Add Swift output option
    arguments.append("--swift-output")
    arguments.append(outputFile.path)

    // Add prefix for generated functions
    // FIXME: Target names with hyphens (e.g. "plugin-demo") create invalid Swift identifiers
    // in generated code like "plugin-demoDrawCircleImage". Use underscores or
    // camelCase instead.
    arguments.append("--objc-prefix")
    arguments.append(target.name.capitalized)

    // Use swift-friendly style for better Swift integration
    arguments.append("--generation-style")
    arguments.append("swift-friendly")

    return [
      .buildCommand(
        displayName: "Generating Swift code from SVG/PDF files for \(target.name)",
        executable: cggenTool.url,
        arguments: arguments,
        inputFiles: inputFiles.map { $0.url },
        outputFiles: [outputFile]
      ),
    ]
  }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension Plugin: XcodeBuildToolPlugin {
  func createBuildCommands(
    context: XcodePluginContext,
    target: XcodeTarget
  ) throws -> [Command] {
    // Find SVG and PDF files in the target
    let inputFiles = target.inputFiles.filter { file in
      file.url.pathExtension == "svg" || file.url.pathExtension == "pdf"
    }

    guard !inputFiles.isEmpty else {
      print("CggenPlugin: No SVG or PDF files found in \(target.displayName)")
      return []
    }

    print(
      "CggenPlugin: Found \(inputFiles.count) files in \(target.displayName)"
    )

    // Create output directory
    let outputDir = context.pluginWorkDirectoryURL.appending(path: "Generated")
    let outputFile = outputDir
      .appending(path: "\(target.displayName)_Generated.swift")

    // Get cggen tool
    let cggenTool = try context.tool(named: "cggen")

    // Build arguments
    var arguments: [String] = []

    for file in inputFiles {
      arguments.append(file.url.path)
    }

    arguments.append("--swift-output")
    arguments.append(outputFile.path)
    // FIXME: Target names with hyphens create invalid Swift identifiers (see SPM plugin above)
    arguments.append("--objc-prefix")
    arguments.append(target.displayName.capitalized)
    arguments.append("--generation-style")
    arguments.append("swift-friendly")

    return [
      .buildCommand(
        displayName: "Generating Swift code from SVG/PDF files for \(target.displayName)",
        executable: cggenTool.url,
        arguments: arguments,
        inputFiles: inputFiles.map { $0.url },
        outputFiles: [outputFile]
      ),
    ]
  }
}
#endif
