import AppKit
import CoreGraphics
import os.log

import CGGenCLI
import CGGenCore
import CGGenDiagnosticSupport
@_spi(Testing) import CGGenRTSupport

private enum Error: Swift.Error {
  case compilationError
}

// Test debug output directory from environment variable
let testDebugOutputDir = ProcessInfo.processInfo
  .environment["CGGEN_TEST_DEBUG_OUTPUT"]
  .map { URL(fileURLWithPath: $0) }

func getCurrentFilePath(_ file: StaticString = #filePath) -> URL {
  URL(fileURLWithPath: file.description, isDirectory: false)
    .deletingLastPathComponent()
}

// Minimal clang support for BCCompilationTests
private func check_output(cmd: String...) throws -> (out: String, err: String) {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  task.arguments = cmd
  let outputPipe = Pipe()
  let errorPipe = Pipe()

  task.standardOutput = outputPipe
  task.standardError = errorPipe
  try task.run()
  let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
  let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(decoding: outputData, as: UTF8.self)
  let error = String(decoding: errorData, as: UTF8.self)
  return (output, error)
}

private let sdkPath = try! check_output(
  cmd: "xcrun", "--sdk", "macosx", "--show-sdk-path"
).out.trimmingCharacters(in: .newlines)

func clang(
  out: URL?,
  files: [URL],
  syntaxOnly: Bool = false,
  frameworks: [String]
) throws {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: "/usr/bin/env")

  let frameworkArgs = frameworks.flatMap { ["-framework", $0] }
  let outArgs = out.map { ["-o", $0.path] } ?? []
  let syntaxOnlyArg = syntaxOnly ? ["-fsyntax-only"] : []

  task.arguments = [
    "clang",
    "-Weverything",
    "-Werror",
    "-Wno-declaration-after-statement",
    "-Wno-poison-system-directories",
    "-fmodules",
    "-isysroot",
    sdkPath,
  ] + outArgs + frameworkArgs + syntaxOnlyArg + files.map(\.path)

  try task.run()
  task.waitUntilExit()

  try check(task.terminationStatus == 0, Error.compilationError)
}

// MARK: - Shared Bytecode Helpers

// Shared helper to render bytecode to CGImage
func renderBytecode(
  _ bytecode: [UInt8],
  width: Int,
  height: Int,
  scale: CGFloat,
  antialiasing: Bool = true
) throws -> CGImage {
  try ReferenceRendering.renderBytecode(
    bytecode,
    width: width,
    height: height,
    scale: scale,
    antialiasing: antialiasing
  )
}

func testBC(
  path: URL,
  referenceRenderer: (URL) throws -> CGImage,
  scale: CGFloat,
  antialiasing: Bool = true,
  resultAdjust: (CGImage) -> CGImage = { $0 },
  tolerance: Double
) throws {
  let reference = try referenceRenderer(path)
  let (bytecode, _) = try getImageBytecode(from: path)

  let rawResult = try renderBytecode(
    bytecode,
    width: reference.width,
    height: reference.height,
    scale: scale,
    antialiasing: antialiasing
  )

  let result = resultAdjust(rawResult)
  let diff = ImageComparison.compare(reference, result)

  try check(
    diff < tolerance,
    Err(
      "Diff \(diff) exceeds tolerance \(tolerance) for \(path.lastPathComponent)"
    )
  )

  // Save debug output if directory is specified and test fails
  if diff >= tolerance, let debugDir = testDebugOutputDir {
    saveTestFailureArtifacts(
      testName: path.deletingPathExtension().lastPathComponent,
      reference: reference,
      result: result,
      diff: diff,
      tolerance: tolerance,
      to: debugDir
    )
  }
}

// MARK: - Test Debug Output

func saveTestFailureArtifacts(
  testName: String,
  reference: CGImage,
  result: CGImage,
  diff: Double,
  tolerance: Double,
  to outputDir: URL
) {
  let testDir = outputDir.appendingPathComponent(testName)
  try? FileManager.default.createDirectory(
    at: testDir,
    withIntermediateDirectories: true
  )

  // Save images
  try? reference.savePNG(to: testDir.appendingPathComponent("reference.png"))
  try? result.savePNG(to: testDir.appendingPathComponent("result.png"))
  try? CGImage.diff(lhs: reference, rhs: result)
    .savePNG(to: testDir.appendingPathComponent("diff.png"))

  // Save metadata
  let metadata: [String: Any] = [
    "test": testName,
    "diff": diff,
    "tolerance": tolerance,
    "timestamp": ISO8601DateFormatter().string(from: Date()),
  ]
  try? JSONSerialization.data(withJSONObject: metadata)
    .write(to: testDir.appendingPathComponent("info.json"))
}
