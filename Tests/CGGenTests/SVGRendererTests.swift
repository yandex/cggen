import CGGenRuntime
import CoreGraphics
import Foundation
import Testing

@Suite struct SVGRendererTests {
  func render(
    _ svg: String,
    size: CGSize = .init(width: 100, height: 100)
  ) throws -> CGImage {
    try SVGRenderer.createCGImage(from: Data(svg.utf8), size: size)
  }

  @Test func emptyData() {
    #expect(throws: Error.self) { try render("") }
  }

  @Test func invalidSVG() {
    #expect(throws: Error.self) { try render("bad") }
  }

  @Test func invalidSize() {
    #expect(throws: SVGRenderer.Error.invalidSize) {
      try render(#"<svg width="100" height="100"/>"#, size: .zero)
    }
  }

  @Test func fillRect() throws {
    let svg = #"""
    <svg width="50" height="50" viewBox="0 0 50 50" xmlns="http://www.w3.org/2000/svg">
        <rect fill="#50E3C2" x="0" y="0" width="50" height="50"/>
    </svg>
    """#

    let image = try render(svg, size: CGSize(width: 50, height: 50))
    #expect(!isImageEmpty(image))
  }

  func isImageEmpty(_ image: CGImage) -> Bool {
    // Check if the image has any non-white pixels
    let width = image.width
    let height = image.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let totalBytes = height * bytesPerRow

    guard let data = image.dataProvider?.data,
          let bytes = CFDataGetBytePtr(data) else {
      return true
    }

    // Check if all pixels are white (255, 255, 255)
    for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
      let r = bytes[i]
      let g = bytes[i + 1]
      let b = bytes[i + 2]

      // If we find any non-white pixel, the image is not empty
      if r != 255 || g != 255 || b != 255 {
        return false
      }
    }

    return true
  }
}
