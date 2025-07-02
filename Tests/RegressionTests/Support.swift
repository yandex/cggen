import AppKit
import CoreGraphics
import os.log

import Base
import CGGenCLI
@_spi(Testing) import CGGenRTSupport

private enum Error: Swift.Error {
  case compilationError
}

// Test debug output directory from environment variable
private let testDebugOutputDir = ProcessInfo.processInfo
  .environment["CGGEN_TEST_DEBUG_OUTPUT"]
  .map { URL(fileURLWithPath: $0) }

// Image comparison for SnapshotTesting
enum SnapshotTestingSupport {
  static func compare(_ img1: CGImage, _ img2: CGImage) -> Double {
    let buffer1 = RGBABuffer(image: img1)
    let buffer2 = RGBABuffer(image: img2)

    let rw1 = buffer1.pixels
      .flatMap(\.self)
      .flatMap { $0.norm(Double.self).components }

    let rw2 = buffer2.pixels
      .flatMap(\.self)
      .flatMap { $0.norm(Double.self).components }

    let ziped = zip(rw1, rw2).lazy.map(-)
    return ziped.rootMeanSquare()
  }
}

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

struct Err: Swift.Error {
  var description: String

  init(_ desc: String) {
    description = desc
  }
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
  let cs = CGColorSpaceCreateDeviceRGB()
  guard let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  ) else {
    throw Err("Failed to create CGContext")
  }

  context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
  context.setAllowsAntialiasing(antialiasing)
  try runBytecode(context, fromData: Data(bytecode))

  guard let image = context.makeImage() else {
    throw Err("Failed to draw CGImage")
  }

  return image
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
  let diff = SnapshotTestingSupport.compare(reference, result)

  try check(
    diff < tolerance,
    Err(
      "Diff \(diff) exceeds tolerance \(tolerance) for \(path.lastPathComponent)"
    )
  )

  // Debug output removed - handled by test framework if needed
}
