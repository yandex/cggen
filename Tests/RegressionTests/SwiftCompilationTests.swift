import CoreGraphics
import Foundation
import Testing

import libcggen

@Suite struct SwiftCompilationTests {
  @Test func testSwiftCodeCompilation() throws {
    let svgSamplesPath = getCurentFilePath()
      .appendingPathComponent("svg_samples")
    let files = [
      "shapes.svg",
      "lines.svg",
    ].map { svgSamplesPath.appendingPathComponent($0) }

    let fm = FileManager.default
    let tmpdir = try fm.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: fm.homeDirectoryForCurrentUser,
      create: true
    )
    defer {
      do {
        try fm.removeItem(at: tmpdir)
      } catch {
        fatalError("Unable to clean up dir: \(tmpdir), error: \(error)")
      }
    }

    let swiftFile = tmpdir.appendingPathComponent("generated.swift")

    // Generate Swift code
    try runCggen(
      with: .init(
        objcHeader: nil,
        objcPrefix: "Test",
        objcImpl: nil,
        objcHeaderImportPath: nil,
        objcCallerPath: nil,
        callerScale: 1,
        callerAllowAntialiasing: false,
        callerPngOutputPath: nil,
        generationStyle: .plain,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { $0.path },
        swiftOutput: swiftFile.path
      )
    )

    // Read the generated code and remove the CGGenRuntimeSupport import
    let generatedCode = try String(contentsOf: swiftFile)
    let codeWithoutImport = generatedCode
      .replacingOccurrences(of: "import CGGenRuntimeSupport\n", with: "")
      .replacingOccurrences(of: "typealias Drawing = CGGenRuntimeSupport.Drawing\n", with: "")

    // Create a test program that imports and uses the generated code
    let testProgram = """
    import CoreGraphics
    import Foundation

    // Include generated code (without CGGenRuntimeSupport import)
    \(codeWithoutImport)

    // Test that we can instantiate the generated types and call functions
    public func testGeneratedCode() {
      if let context = CGContext(
        data: nil,
        width: 100,
        height: 100,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) {
        testDrawShapesImage(in: context)
      }
    }
    """

    let testFile = tmpdir.appendingPathComponent("test.swift")
    try testProgram.write(to: testFile, atomically: true, encoding: .utf8)

    // Create a mock for the @_silgen_name functions and CGGenRuntimeSupport
    let mockRuntime = """
    // Mock runtime functions for testing
    import CoreGraphics

    // Mock CGGenRuntimeSupport module
    public struct Drawing {
      public let size: CGSize
      public let draw: (CGContext) -> Void
      
      public init(size: CGSize, draw: @escaping (CGContext) -> Void) {
        self.size = size
        self.draw = draw
      }
    }

    @_silgen_name("runMergedBytecode_swift")
    fileprivate func runMergedBytecode(
      _ context: CGContext,
      _ data: UnsafePointer<UInt8>,
      _ decompressedLen: Int32,
      _ compressedLen: Int32,
      _ startIndex: Int32,
      _ endIndex: Int32
    ) {
      // Mock implementation for testing
    }

    @_silgen_name("runPathBytecode_swift")
    fileprivate func runPathBytecode(
      _ path: CGMutablePath,
      _ data: UnsafePointer<UInt8>,
      _ len: Int32
    ) {
      // Mock implementation for testing
    }
    """

    let mockRuntimeFile = tmpdir.appendingPathComponent("MockRuntime.swift")
    try mockRuntime.write(
      to: mockRuntimeFile,
      atomically: true,
      encoding: .utf8
    )

    // Compile both files together
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
    process.arguments = [
      "-parse-as-library", // Parse as library to avoid needing main
      "-typecheck", // Type check the code
      mockRuntimeFile.path,
      testFile.path,
    ]

    let pipe = Pipe()
    process.standardError = pipe
    process.standardOutput = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
      let generatedCode = try String(contentsOf: swiftFile)
      Issue.record("""
      Swift compilation failed with status \(process.terminationStatus)
      Output: \(output)

      Generated Swift file contents:
      \(generatedCode)
      """)
    }

    #expect(process.terminationStatus == 0)
  }

  @Test func testSwiftCodeGenerationSnapshot() throws {
    // Use the plugindemo SVG files for a consistent snapshot test
    let plugindemoPath = getCurentFilePath()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Sources")
      .appendingPathComponent("plugindemo")

    let files = [
      "circle.svg",
      "square.svg",
      "star.svg",
    ].map { plugindemoPath.appendingPathComponent($0) }

    let fm = FileManager.default
    let tmpdir = try fm.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: fm.homeDirectoryForCurrentUser,
      create: true
    )
    defer {
      do {
        try fm.removeItem(at: tmpdir)
      } catch {
        fatalError("Unable to clean up dir: \(tmpdir), error: \(error)")
      }
    }

    let swiftFile = tmpdir.appendingPathComponent("PluginDemoGenerated.swift")

    try runCggen(
      with: .init(
        objcHeader: nil,
        objcPrefix: "plugindemo",
        objcImpl: nil,
        objcHeaderImportPath: nil,
        objcCallerPath: nil,
        callerScale: 1.0,
        callerAllowAntialiasing: false,
        callerPngOutputPath: nil,
        generationStyle: .swiftFriendly,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { $0.path },
        swiftOutput: swiftFile.path
      )
    )

    let generatedCode = try String(contentsOf: swiftFile, encoding: .utf8)

    // Follow swift-snapshot-testing conventions: __Snapshots__/
    let snapshotPath = getCurentFilePath()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent("SwiftCompilationTests")
      .appendingPathComponent("testSwiftCodeGenerationSnapshot.swift")

    // Create directory if it doesn't exist
    try fm.createDirectory(
      at: snapshotPath.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    if fm.fileExists(atPath: snapshotPath.path) {
      // Compare with existing snapshot
      let expectedCode = try String(contentsOf: snapshotPath, encoding: .utf8)

      if generatedCode != expectedCode {
        // Write actual output for debugging
        let actualPath = snapshotPath.appendingPathExtension("actual")
        try generatedCode.write(
          to: actualPath,
          atomically: true,
          encoding: .utf8
        )

        Issue.record("""
        Generated Swift code doesn't match snapshot!

        Expected: \(snapshotPath.path)
        Actual: \(actualPath.path)

        Run `diff \(snapshotPath.path) \(actualPath.path)` to see differences.
        To update snapshot: `mv \(actualPath.path) \(snapshotPath.path)`
        """)
      }
    } else {
      // Create initial snapshot
      try generatedCode.write(
        to: snapshotPath,
        atomically: true,
        encoding: .utf8
      )
      print("Created initial snapshot at: \(snapshotPath.path)")
    }
  }
}
