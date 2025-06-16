import Foundation
import PackagePlugin

@main
struct Plugin: BuildToolPlugin {
  /// Sanitizes a string to be a valid Swift identifier prefix
  /// - Replaces hyphens with underscores
  /// - Ensures the result starts with a letter or underscore
  /// - Removes any invalid characters
  static func sanitizeForSwiftIdentifier(_ name: String) -> String {
    // Replace hyphens with underscores
    var sanitized = name.replacingOccurrences(of: "-", with: "_")

    // Remove any characters that aren't alphanumeric or underscore
    sanitized = sanitized.filter { $0.isLetter || $0.isNumber || $0 == "_" }

    // Ensure it doesn't start with a number
    if let first = sanitized.first, first.isNumber {
      sanitized = "_" + sanitized
    }

    // If empty after sanitization, provide a default
    if sanitized.isEmpty {
      sanitized = "Generated"
    }

    return sanitized
  }

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
      "CggenPlugin: Found \(inputFiles.count) files in \(target.name): \(inputFiles.map(\.url.lastPathComponent))"
    )

    // Create output directory for generated Swift files
    let outputDir = context.pluginWorkDirectoryURL.appending(path: "Generated")
    let outputFile = outputDir.appending(path: "\(target.name)_Generated.swift")

    // Get the cggen tool
    let cggenTool = try context.tool(named: "cggen-tool")

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
    arguments.append("--objc-prefix")
    arguments.append(Self.sanitizeForSwiftIdentifier(target.name).capitalized)

    // Use swift-friendly style for better Swift integration
    arguments.append("--generation-style")
    arguments.append("swift-friendly")

    return [
      .buildCommand(
        displayName: "Generating Swift code from SVG/PDF files for \(target.name)",
        executable: cggenTool.url,
        arguments: arguments,
        inputFiles: inputFiles.map(\.url),
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
    let cggenTool = try context.tool(named: "cggen-tool")

    // Build arguments
    var arguments: [String] = []

    for file in inputFiles {
      arguments.append(file.url.path)
    }

    arguments.append("--swift-output")
    arguments.append(outputFile.path)
    arguments.append("--objc-prefix")
    arguments
      .append(Self.sanitizeForSwiftIdentifier(target.displayName).capitalized)
    arguments.append("--generation-style")
    arguments.append("swift-friendly")

    return [
      .buildCommand(
        displayName: "Generating Swift code from SVG/PDF files for \(target.displayName)",
        executable: cggenTool.url,
        arguments: arguments,
        inputFiles: inputFiles.map(\.url),
        outputFiles: [outputFile]
      ),
    ]
  }
}
#endif
