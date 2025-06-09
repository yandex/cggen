import Foundation
import Testing

import libcggen

// MARK: - Snapshot Testing Infrastructure

struct SnapshotTest {
  let name: String
  let files: [URL]
  let prefix: String
  let generationStyle: GenerationStyle
  let snapshotFileName: String

  init(
    name: String,
    files: [URL],
    prefix: String = "test",
    generationStyle: GenerationStyle = .swiftFriendly,
    snapshotFileName: String? = nil
  ) {
    self.name = name
    self.files = files
    self.prefix = prefix
    self.generationStyle = generationStyle
    self.snapshotFileName = snapshotFileName ?? "\(name).swift"
  }
}

// MARK: - Test Types

enum GenerationType {
  case swift(GenerationStyle)
  case objcHeader
  case objcImplementation
}

@Suite struct CodeGenerationSnapshotTests {
  // MARK: - Swift Generation Tests

  @Test func testPluginDemoGeneration() throws {
    let test = SnapshotTest(
      name: "testSwiftCodeGenerationSnapshot",
      files: pluginDemoFiles(["circle.svg", "square.svg", "star.svg"]),
      prefix: "plugindemo"
    )
    try runSnapshotTest(test)
  }

  @Test func testPathGeneration() throws {
    let test = SnapshotTest(
      name: "testSwiftPathGenerationSnapshot_paths",
      files: pluginDemoFiles(["paths.svg"])
    )
    try runSnapshotTest(test)
  }

  @Test func testMixedGeneration() throws {
    let test = SnapshotTest(
      name: "testSwiftMixedGenerationSnapshot_mixed",
      files: svgSampleFiles(["paths_and_images.svg"]),
      prefix: "mixed"
    )
    try runSnapshotTest(test)
  }

  // MARK: - C/Objective-C Generation Tests

  @Test func testObjCHeaderGeneration() throws {
    let files = pluginDemoFiles(["circle.svg", "square.svg", "star.svg"])
    let generatedCode = try generateObjCHeader(files: files, prefix: "test")
    try assertSnapshot(
      generatedCode,
      testName: "testObjCHeaderGenerationSnapshot",
      fileName: "testObjCHeaderGenerationSnapshot.h"
    )
  }

  @Test func testObjCImplementationGeneration() throws {
    let files = pluginDemoFiles(["circle.svg", "square.svg", "star.svg"])
    let generatedCode = try generateObjCImplementation(
      files: files,
      prefix: "test"
    )
    try assertSnapshot(
      generatedCode,
      testName: "testObjCImplementationGenerationSnapshot",
      fileName: "testObjCImplementationGenerationSnapshot.m"
    )
  }

  @Test func testObjCPathGeneration() throws {
    let files = pluginDemoFiles(["paths.svg"])
    let generatedCode = try generateObjCImplementation(
      files: files,
      prefix: "test"
    )
    try assertSnapshot(
      generatedCode,
      testName: "testObjCPathGenerationSnapshot",
      fileName: "testObjCPathGenerationSnapshot.m"
    )
  }

  // MARK: - Infrastructure

  private func runSnapshotTest(_ test: SnapshotTest) throws {
    let generatedCode = try generateSwiftCode(
      files: test.files,
      prefix: test.prefix,
      generationStyle: test.generationStyle
    )

    try assertSnapshot(
      generatedCode,
      testName: test.name,
      fileName: test.snapshotFileName
    )
  }

  private func generateSwiftCode(
    files: [URL],
    prefix: String,
    generationStyle: GenerationStyle
  ) throws -> String {
    let tmpdir = try createTempDirectory()
    defer { cleanupTempDirectory(tmpdir) }

    let swiftFile = tmpdir.appendingPathComponent("generated.swift")

    try runCggen(
      with: .init(
        objcHeader: nil,
        objcPrefix: prefix,
        objcImpl: nil,
        objcHeaderImportPath: nil,
        objcCallerPath: nil,
        callerScale: 1.0,
        callerAllowAntialiasing: false,
        callerPngOutputPath: nil,
        generationStyle: generationStyle,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { $0.path },
        swiftOutput: swiftFile.path
      )
    )

    return try String(contentsOf: swiftFile, encoding: .utf8)
  }

  private func generateObjCHeader(
    files: [URL],
    prefix: String
  ) throws -> String {
    let tmpdir = try createTempDirectory()
    defer { cleanupTempDirectory(tmpdir) }

    let headerFile = tmpdir.appendingPathComponent("generated.h")

    try runCggen(
      with: .init(
        objcHeader: headerFile.path,
        objcPrefix: prefix,
        objcImpl: nil,
        objcHeaderImportPath: nil,
        objcCallerPath: nil,
        callerScale: 1.0,
        callerAllowAntialiasing: false,
        callerPngOutputPath: nil,
        generationStyle: .plain,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { $0.path },
        swiftOutput: nil
      )
    )

    return try String(contentsOf: headerFile, encoding: .utf8)
  }

  private func generateObjCImplementation(
    files: [URL],
    prefix: String
  ) throws -> String {
    let tmpdir = try createTempDirectory()
    defer { cleanupTempDirectory(tmpdir) }

    let implFile = tmpdir.appendingPathComponent("generated.m")

    try runCggen(
      with: .init(
        objcHeader: nil,
        objcPrefix: prefix,
        objcImpl: implFile.path,
        objcHeaderImportPath: nil,
        objcCallerPath: nil,
        callerScale: 1.0,
        callerAllowAntialiasing: false,
        callerPngOutputPath: nil,
        generationStyle: .plain,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { $0.path },
        swiftOutput: nil
      )
    )

    return try String(contentsOf: implFile, encoding: .utf8)
  }

  private func assertSnapshot(
    _ actual: String,
    testName _: String,
    fileName: String
  ) throws {
    let snapshotPath = snapshotDirectory()
      .appendingPathComponent("SwiftCompilationTests")
      .appendingPathComponent(fileName)

    let fm = FileManager.default

    // Create directory if needed
    try fm.createDirectory(
      at: snapshotPath.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    if fm.fileExists(atPath: snapshotPath.path) {
      // Compare with existing snapshot
      let expected = try String(contentsOf: snapshotPath, encoding: .utf8)

      if actual != expected {
        // Write actual output for debugging
        let actualPath = snapshotPath.appendingPathExtension("actual")
        try actual.write(to: actualPath, atomically: true, encoding: .utf8)

        Issue.record("""
        Generated Swift code doesn't match snapshot!

        Expected: \(snapshotPath.path)
        Actual: \(actualPath.path)

        Run `diff \(snapshotPath.path) \(actualPath.path)` to see differences.
        To update snapshot: `mv \(actualPath.path) \(snapshotPath.path)`
        """)
      } else {
        // Clean up any leftover .actual file from previous failures
        let actualPath = snapshotPath.appendingPathExtension("actual")
        try? fm.removeItem(at: actualPath)
      }
    } else {
      // Create initial snapshot
      try actual.write(to: snapshotPath, atomically: true, encoding: .utf8)
      print("Created initial snapshot at: \(snapshotPath.path)")
    }
  }

  // MARK: - Helpers

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

  private func snapshotDirectory() -> URL {
    getCurentFilePath()
      .appendingPathComponent("__Snapshots__")
  }

  private func pluginDemoFiles(_ names: [String]) -> [URL] {
    let plugindemoPath = getCurentFilePath()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Sources")
      .appendingPathComponent("plugindemo")

    return names.map { plugindemoPath.appendingPathComponent($0) }
  }

  private func svgSampleFiles(_ names: [String]) -> [URL] {
    let svgSamplesPath = getCurentFilePath()
      .appendingPathComponent("svg_samples")

    return names.map { svgSamplesPath.appendingPathComponent($0) }
  }
}
