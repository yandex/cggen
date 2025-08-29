import Foundation
import SnapshotTesting
import Testing

import CGGenCLI

@Suite struct CodeGenerationSnapshotTests {
  @Test func pluginDemoGeneration() throws {
    try testCodeGeneration(
      files: "circle.svg", "square.svg", "star.svg",
      prefix: "plugin_demo"
    )
  }

  @Test func pathGeneration() throws {
    try testCodeGeneration(files: "paths.svg")
  }

  @Test func mixedGeneration() throws {
    try testCodeGeneration(
      fromSamples: true,
      files: "paths_and_images.svg",
      prefix: "mixed"
    )
  }

  @Test func gradientDeterminismGeneration() throws {
    try testCodeGeneration(
      fromSamples: true,
      files: "gradient_determinism_test.svg",
      prefix: "grad_determ"
    )
  }

  @Test func pdfExtGStateDeterminismGeneration() throws {
    try testCodeGeneration(
      fromSamples: true,
      isPDF: true,
      files: "extgstate_multiple_params.pdf",
      prefix: "pdf_extgstate_determ"
    )
  }

  private func testCodeGeneration(
    fromSamples: Bool = false,
    isPDF: Bool = false,
    files: String...,
    prefix: String = "test",
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
  ) throws {
    let fileURLs = fromSamples ? 
      (isPDF ? pdfSampleFiles(files) : svgSampleFiles(files)) : 
      pluginDemoFiles(files)

    let tmpdir = try createTempDirectory()
    defer { cleanupTempDirectory(tmpdir) }

    let swiftOutput = tmpdir.appendingPathComponent("generated.swift")
    let objcHeader = tmpdir.appendingPathComponent("generated.h")
    let objcImpl = tmpdir.appendingPathComponent("generated.m")

    // Generate all three outputs in one go
    try runCggen(
      with: .init(
        objcHeader: objcHeader.path,
        objcPrefix: prefix,
        objcImpl: objcImpl.path,
        objcHeaderImportPath: nil,
        generationStyle: .plain,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: fileURLs.map(\.path),
        swiftOutput: swiftOutput.path
      )
    )

    // Test all three outputs  
    let outputs: [(file: URL, ext: String)] = [
      (swiftOutput, "swift"),
      (objcHeader, "h"),
      (objcImpl, "m"),
    ]

    for (outputFile, ext) in outputs {
      let generatedCode = try String(contentsOf: outputFile, encoding: .utf8)
      
      var strategy = Snapshotting<String, String>.lines
      strategy.pathExtension = ext

      assertSnapshot(
        of: generatedCode,
        as: strategy,
        named: nil,
        file: file,
        testName: testName,
        line: line
      )
    }
  }

  private func createTempDirectory() throws -> URL {
    let fm = FileManager.default
    return try fm.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: fm.homeDirectoryForCurrentUser,
      create: true
    )
  }

  private func cleanupTempDirectory(_ tmpdir: URL) {
    do {
      try FileManager.default.removeItem(at: tmpdir)
    } catch {
      fatalError("Unable to clean up dir: \(tmpdir), error: \(error)")
    }
  }

  private func pluginDemoFiles(_ names: [String]) -> [URL] {
    let plugindemoPath = getCurrentFilePath()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Sources")
      .appendingPathComponent("plugin-demo")

    return names.map { plugindemoPath.appendingPathComponent($0) }
  }

  private func svgSampleFiles(_ names: [String]) -> [URL] {
    let svgSamplesPath = getCurrentFilePath()
      .appendingPathComponent("svg_samples")

    return names.map { svgSamplesPath.appendingPathComponent($0) }
  }

  private func pdfSampleFiles(_ names: [String]) -> [URL] {
    let pdfSamplesPath = getCurrentFilePath()
      .appendingPathComponent("pdf_samples")

    return names.map { pdfSamplesPath.appendingPathComponent($0) }
  }
}
