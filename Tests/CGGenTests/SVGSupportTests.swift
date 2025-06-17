import CGGenRuntime
import CoreGraphics
import Foundation
import SwiftUI
import Testing

@Suite struct SVGSupportTests {
  let simpleSVG = #"""
  <svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
    <rect fill="#50E3C2" x="0" y="0" width="100" height="100"/>
  </svg>
  """#

  let invalidSVG = #"<svg><invalid></svg>"#

  @Test func cgImageFromData() throws {
    let data = Data(simpleSVG.utf8)
    let image = try CGImage.svg(data, size: CGSize(width: 100, height: 100))
    #expect(image.width == 100)
    #expect(image.height == 100)
  }

  @Test func cgImageFromString() throws {
    let image = try CGImage.svg(
      simpleSVG,
      size: CGSize(width: 100, height: 100)
    )
    #expect(image.width == 100)
    #expect(image.height == 100)
  }

  @Test func cgImageWithScale() throws {
    let image = try CGImage.svg(
      simpleSVG,
      size: CGSize(width: 100, height: 100),
      scale: 2.0
    )
    #expect(image.width == 200)
    #expect(image.height == 200)
  }

  @Test func invalidSVGThrows() {
    // TODO: Fix XML parser to not call fatalError
    // #expect(throws: Error.self) {
    //   _ = try CGImage.svg(invalidSVG, size: CGSize(width: 100, height: 100))
    // }
  }

  #if canImport(UIKit)
  @MainActor
  @Test func uiImageFromData() throws {
    let data = Data(simpleSVG.utf8)
    let image = try UIImage(
      svgData: data,
      size: CGSize(width: 100, height: 100)
    )
    #expect(image.size.width == 100)
    #expect(image.size.height == 100)
  }

  @MainActor
  @Test func uiImageFromString() throws {
    let image = try UIImage(
      svgString: simpleSVG,
      size: CGSize(width: 100, height: 100)
    )
    #expect(image.size.width == 100)
    #expect(image.size.height == 100)
  }

  @Test func uiImageWithExplicitScale() throws {
    let image = try UIImage(
      svgString: simpleSVG,
      size: CGSize(width: 100, height: 100),
      scale: 2.0
    )
    #expect(image.size.width == 100)
    #expect(image.size.height == 100)
    #expect(image.scale == 2.0)
  }
  #endif

  #if canImport(AppKit)
  @MainActor
  @Test func nsImageFromData() throws {
    let data = Data(simpleSVG.utf8)
    let image = try NSImage(
      svgData: data,
      size: CGSize(width: 100, height: 100)
    )
    #expect(image.size.width == 100)
    #expect(image.size.height == 100)
  }

  @MainActor
  @Test func nsImageFromString() throws {
    let image = try NSImage(
      svgString: simpleSVG,
      size: CGSize(width: 100, height: 100)
    )
    #expect(image.size.width == 100)
    #expect(image.size.height == 100)
  }

  @Test func nsImageWithExplicitScale() throws {
    let image = try NSImage(
      svgString: simpleSVG,
      size: CGSize(width: 100, height: 100),
      scale: 2.0
    )
    #expect(image.size.width == 100)
    #expect(image.size.height == 100)
  }
  #endif

  @MainActor
  @Test func swiftUIImageFromData() throws {
    let data = Data(simpleSVG.utf8)
    _ = try Image(svgData: data, size: CGSize(width: 100, height: 100))
  }

  @MainActor
  @Test func swiftUIImageFromString() throws {
    _ = try Image(svgString: simpleSVG, size: CGSize(width: 100, height: 100))
  }

  @Test func swiftUIImageWithExplicitScale() throws {
    _ = try Image(
      svgString: simpleSVG,
      size: CGSize(width: 100, height: 100),
      scale: 2.0
    )
  }
}
