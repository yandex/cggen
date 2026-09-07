import CGGenCLI
import CoreGraphics
import Foundation
import SnapshotTesting
import Testing
@_spi(Generator) import CGGenRTSupport

struct DrawingTintTests {
  @Test func gradientsAndOpacity() throws {
    try assertTintedSnapshot("gradients_and_opacity")
  }

  @Test func clippedPaths() throws {
    try assertTintedSnapshot("clipped_paths")
  }
}

private func assertTintedSnapshot(
  _ name: String,
  file: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line
) throws {
  let url = try #require(Bundle.module.url(
    forResource: name, withExtension: "svg", subdirectory: "tint_samples"
  ))
  let (bytecode, positions, decompressedSize, sizes) =
    try getImagesMergedBytecodeAndPositions(from: [url])
  let position = try #require(positions.first)
  let size = try #require(sizes.first)
  let drawing = Drawing(
    width: Float(size.width), height: Float(size.height),
    bytecodeArray: bytecode, decompressedSize: Int32(decompressedSize),
    startIndex: Int32(position.0), endIndex: Int32(position.1)
  )
  let image = try #require(CGImage.draw(
    from: drawing,
    scale: 1,
    tintColor: CGColor(red: 0.35, green: 0.2, blue: 0.85, alpha: 1)
  ))
  assertSnapshot(
    of: image, as: .cgImage(), file: file, testName: testName, line: line
  )
}
