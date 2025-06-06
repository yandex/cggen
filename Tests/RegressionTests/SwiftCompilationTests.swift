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
        generationStyle: .swiftFriendly,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { $0.path },
        swiftOutput: swiftFile.path
      )
    )

    // Create a test program that imports and uses the generated code
    let testProgram = try """
    import CoreGraphics
    import Foundation

    // Include generated code
    \(String(contentsOf: swiftFile))

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

        // Test descriptors exist and have correct properties
        let _ = testShapesDescriptor.size
        let _ = testShapesDescriptor.draw
      }
    }
    """

    let testFile = tmpdir.appendingPathComponent("test.swift")
    try testProgram.write(to: testFile, atomically: true, encoding: .utf8)

    // Create a mock CGGenRuntimeSupport module that provides the C functions
    let mockCGGenRuntimeSupport = """
    // Mock CGGenRuntimeSupport.swift - provides Swift calling convention functions for testing
    import CoreGraphics

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

    let mockCGGenRuntimeSupportFile = tmpdir.appendingPathComponent("CGGenRuntimeSupport.swift")
    try mockCGGenRuntimeSupport.write(
      to: mockCGGenRuntimeSupportFile,
      atomically: true,
      encoding: .utf8
    )

    // Compile both files together
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
    process.arguments = [
      "-parse-as-library", // Parse as library to avoid needing main
      "-typecheck", // Type check the code
      mockCGGenRuntimeSupportFile.path,
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
}
