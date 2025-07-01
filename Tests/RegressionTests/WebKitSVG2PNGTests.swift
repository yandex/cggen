import Base
import CoreGraphics
import Foundation
import SnapshotTesting
import Testing

@Suite(.enabled(if: extendedTestsEnabled))
struct WebKitSVG2PNGTests {
  @MainActor
  @Test func simpleSVGConversion() async throws {
    let cgImage = try await convertSVG("""
    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <rect x="10" y="10" width="80" height="80" fill="red" />
      <circle cx="50" cy="50" r="30" fill="blue" />
    </svg>
    """, scale: 2.0)

    expectSize(cgImage, width: 200, height: 200)
    snapshot(cgImage, named: "simple-svg")
  }

  @MainActor
  @Test func svgWithGradient() async throws {
    let cgImage = try await convertSVG("""
    <svg width="200" height="100" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad1">
          <stop offset="0%" stop-color="yellow" />
          <stop offset="100%" stop-color="red" />
        </linearGradient>
      </defs>
      <rect width="200" height="100" fill="url(#grad1)" />
    </svg>
    """)

    expectSize(cgImage, width: 200, height: 100)
    snapshot(cgImage, named: "gradient-svg")
  }

  @MainActor
  @Test func complexSVGFromTestSuite() async throws {
    let cgImage = try await convertSVGFromFile("gradient", scale: 2.0)

    expectSize(cgImage, width: 100, height: 100)
    snapshot(
      cgImage.redraw(with: .white),
      named: "gradient-from-suite",
      tolerance: 0.002
    )
  }

  @MainActor
  @Test func invalidSVG() async throws {
    await #expect(throws: (any Error).self) {
      _ = try await convertSVG("<svg>broken")
    }
  }

  @MainActor
  @Test func multipleConversions() async throws {
    let converter = WebKitSVG2PNG()

    let image1 = try await converter.convertToCGImage(svg: """
    <svg width="50" height="50" xmlns="http://www.w3.org/2000/svg">
      <rect width="50" height="50" fill="red" />
    </svg>
    """)
    expectSize(image1, width: 50, height: 50)

    let image2 = try await converter.convertToCGImage(svg: """
    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="50" r="40" fill="blue" />
    </svg>
    """)
    expectSize(image2, width: 100, height: 100)
  }
}

// MARK: - Helpers

extension WebKitSVG2PNGTests {
  @MainActor
  private func convertSVG(
    _ svg: String,
    scale: CGFloat = 1.0
  ) async throws -> CGImage {
    let converter = WebKitSVG2PNG()
    return try await converter.convertToCGImage(svg: svg, scale: scale)
  }

  @MainActor
  private func convertSVGFromFile(
    _ filename: String,
    scale: CGFloat = 1.0
  ) async throws -> CGImage {
    let svgPath = svgSamplesPath
      .appendingPathComponent(filename)
      .appendingPathExtension("svg")
    let svgContent = try String(contentsOf: svgPath)
    return try await convertSVG(svgContent, scale: scale)
  }

  private func expectSize(_ image: CGImage, width: Int, height: Int) {
    #expect(image.width == width)
    #expect(image.height == height)
  }

  private func snapshot(
    _ image: CGImage,
    named name: String,
    tolerance: Double = 0.0001,
    file: StaticString = #filePath,
    testName: String = #function
  ) {
    assertSnapshot(
      of: image,
      as: .cgImage(tolerance: tolerance),
      named: name,
      file: file,
      testName: testName
    )
  }
}
