import Foundation
import XCTest
import SnapshotTesting
import Base

class WebKitSVG2PNGTests: XCTestCase {
  @MainActor
  func testSimpleSVGConversion() async throws {
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
    XCTAssertEqual(cgImage.width, 200) // 100 * 2.0 scale
    XCTAssertEqual(cgImage.height, 200)
    
    // Snapshot test to verify the image is correct
    assertSnapshot(
      of: cgImage,
      as: .cgImage(),
      named: "simple-svg"
    )
  }
  
  @MainActor
  func testSVGWithGradient() async throws {
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
    
    XCTAssertEqual(cgImage.width, 200)
    XCTAssertEqual(cgImage.height, 100)
    
    // Snapshot test for gradient rendering
    assertSnapshot(
      of: cgImage,
      as: .cgImage(),
      named: "gradient-svg"
    )
  }
  
  @MainActor
  func testComplexSVGFromTestSuite() async throws {
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
    
    XCTAssertEqual(cgImage.width, 100)
    XCTAssertEqual(cgImage.height, 100)
    
    // Compare with existing webkit snapshot
    assertSnapshot(
      of: cgImage.redraw(with: .white),
      as: .cgImage(tolerance: 0.002),
      named: "gradient-from-suite"
    )
  }
  
  @MainActor 
  func testInvalidSVG() async throws {
    let invalidSVG = "<svg>broken"
    
    let converter = WebKitSVG2PNG()
    
    // Wait for WebView to load
    try await Task.sleep(nanoseconds: 500_000_000)
    
    do {
      _ = try await converter.convertToCGImage(
        svg: invalidSVG,
        width: 100,
        height: 100
      )
      XCTFail("Should have thrown an error")
    } catch {
      // Expected error
      print("Got expected error: \(error)")
    }
  }
}