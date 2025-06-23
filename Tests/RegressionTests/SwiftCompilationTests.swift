import CoreGraphics
import Foundation
import Testing

import CGGenCLI

@Suite struct SwiftCompilationTests {
  @Test func swiftCodeCompilation() throws {
    let svgSamplesPath = getCurrentFilePath()
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
        files: files.map(\.path),
        swiftOutput: swiftFile.path
      )
    )

    // Read the generated code and remove the CGGenRuntimeSupport import
    let generatedCode = try String(contentsOf: swiftFile)
    let codeWithoutImport = generatedCode
      .replacingOccurrences(
        of: "@_spi(Generator) import CGGenRTSupport\n",
        with: ""
      )
      .replacingOccurrences(
        of: "typealias Drawing = CGGenRTSupport.Drawing\n",
        with: ""
      )

    // Create a test program that imports and uses the generated code
    let testProgram = """
    import CoreGraphics
    import Foundation

    // Include generated code (without CGGenRuntimeSupport import)
    \(codeWithoutImport)

    // Test that we can instantiate the generated types and call functions
    public func testGeneratedCode() {
      // Test that Drawing instances are created correctly
      let _ = Drawing.shapes
      let _ = Drawing.lines

      // Test that Drawing is Equatable and Hashable
      if Drawing.shapes == Drawing.shapes {
        print("Equatable works")
      }

      var drawingSet = Set<Drawing>()
      drawingSet.insert(Drawing.shapes)
      drawingSet.insert(Drawing.lines)
    }
    """

    let testFile = tmpdir.appendingPathComponent("test.swift")
    try testProgram.write(to: testFile, atomically: true, encoding: .utf8)

    // Create a mock for the @_silgen_name functions and CGGenRuntimeSupport
    let mockRuntime = """
    // Mock runtime functions for testing
    import CoreGraphics

    // Mock CGGenRuntimeSupport module
    public struct Drawing: Equatable, Hashable {
      internal var width: Float
      internal var height: Float
      internal var bytecode: BytecodeProcedure

      public var size: CGSize {
        CGSize(width: CGFloat(width), height: CGFloat(height))
      }

      internal struct BytecodeProcedure: Equatable, Hashable {
        internal var bytecodeArray: [UInt8]
        internal var decompressedSize: Int32
        internal var startIndex: Int32
        internal var endIndex: Int32
      }

      public init(
        width: Float,
        height: Float,
        bytecodeArray: [UInt8],
        decompressedSize: Int32,
        startIndex: Int32,
        endIndex: Int32
      ) {
        self.width = width
        self.height = height
        self.bytecode = BytecodeProcedure(
          bytecodeArray: bytecodeArray,
          decompressedSize: decompressedSize,
          startIndex: startIndex,
          endIndex: endIndex
        )
      }
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
}
