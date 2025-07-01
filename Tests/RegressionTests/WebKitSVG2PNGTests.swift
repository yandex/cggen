import Base
import Foundation
import SnapshotTesting
import Testing

@Suite struct WebKitSVG2PNGTests {
  @MainActor
  @Test func simpleSVGConversion() async throws {
    let simpleSVG = """
    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <rect x="10" y="10" width="80" height="80" fill="red" />
      <circle cx="50" cy="50" r="30" fill="blue" />
    </svg>
    """

    let converter = WebKitSVG2PNG()

    // Wait for WebView to load
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

    let cgImage = try await converter.convertToCGImage(
      svg: simpleSVG,
      width: 100,
      height: 100,
      scale: 2.0
    )

    // Verify dimensions
    #expect(cgImage.width == 200) // 100 * 2.0 scale
    #expect(cgImage.height == 200)

    // Snapshot test to verify the image is correct
    assertSnapshot(
      of: cgImage,
      as: .cgImage(),
      named: "simple-svg"
    )
  }

  @MainActor
  @Test func svgWithGradient() async throws {
    let gradientSVG = """
    <svg width="200" height="100" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad1">
          <stop offset="0%" stop-color="yellow" />
          <stop offset="100%" stop-color="red" />
        </linearGradient>
      </defs>
      <rect width="200" height="100" fill="url(#grad1)" />
    </svg>
    """

    let converter = WebKitSVG2PNG()

    // Wait for WebView to load
    try await Task.sleep(nanoseconds: 500_000_000)

    let cgImage = try await converter.convertToCGImage(
      svg: gradientSVG,
      width: 200,
      height: 100,
      scale: 1.0
    )

    #expect(cgImage.width == 200)
    #expect(cgImage.height == 100)

    // Snapshot test for gradient rendering
    assertSnapshot(
      of: cgImage,
      as: .cgImage(),
      named: "gradient-svg"
    )
  }

  @MainActor
  @Test func complexSVGFromTestSuite() async throws {
    // Test with an actual SVG from the test suite
    let svgPath = svgSamplesPath
      .appendingPathComponent("gradient")
      .appendingPathExtension("svg")

    let svgContent = try String(contentsOf: svgPath)

    let converter = WebKitSVG2PNG()

    // Wait for WebView to load
    try await Task.sleep(nanoseconds: 500_000_000)

    let cgImage = try await converter.convertToCGImage(
      svg: svgContent,
      width: 50,
      height: 50,
      scale: 2.0
    )

    #expect(cgImage.width == 100)
    #expect(cgImage.height == 100)

    // Compare with existing webkit snapshot
    assertSnapshot(
      of: cgImage.redraw(with: .white),
      as: .cgImage(tolerance: 0.002),
      named: "gradient-from-suite"
    )
  }

  @MainActor
  @Test func invalidSVG() async throws {
    let invalidSVG = "<svg>broken"

    let converter = WebKitSVG2PNG()

    // Wait for WebView to load
    try await Task.sleep(nanoseconds: 500_000_000)

    await #expect(throws: (any Error).self) {
      _ = try await converter.convertToCGImage(
        svg: invalidSVG,
        width: 100,
        height: 100
      )
    }
  }
}
