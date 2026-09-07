import CGGenRTSupport
import CoreGraphics
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension CGGenPlatformImage {
  @MainActor
  @available(*, deprecated, message: "Use svg(_:size:) instead.")
  public convenience init(svgData: Data, size: CGSize) throws {
    #if canImport(UIKit)
    let scale = UIScreen.main.scale
    #elseif canImport(AppKit)
    let scale = NSScreen.main?.backingScaleFactor ?? 1.0
    #endif
    try self.init(svgData: svgData, size: size, scale: scale)
  }

  @MainActor
  @available(*, deprecated, message: "Use svg(_:size:) instead.")
  public convenience init(svgString: String, size: CGSize) throws {
    #if canImport(UIKit)
    let scale = UIScreen.main.scale
    #elseif canImport(AppKit)
    let scale = NSScreen.main?.backingScaleFactor ?? 1.0
    #endif
    try self.init(svgString: svgString, size: size, scale: scale)
  }

  @available(*, deprecated, message: "Use svg(_:size:scale:) instead.")
  public convenience init(svgData: Data, size: CGSize, scale: CGFloat) throws {
    let cgImage = try CGImage.svg(svgData, size: size, scale: scale)
    #if canImport(UIKit)
    self.init(cgImage: cgImage, scale: scale, orientation: .up)
    #elseif canImport(AppKit)
    self.init(cgImage: cgImage, size: size)
    #endif
  }

  @available(*, deprecated, message: "Use svg(_:size:scale:) instead.")
  public convenience init(
    svgString: String,
    size: CGSize,
    scale: CGFloat
  ) throws {
    guard let data = svgString.data(using: .utf8) else {
      throw SVGRenderer.Error.invalidUTF8String
    }
    try self.init(svgData: data, size: size, scale: scale)
  }
}

extension Image {
  @MainActor
  @available(*, deprecated, message: "Use svg(_:size:) instead.")
  public init(svgData: Data, size: CGSize) throws {
    self = try Image.svg(svgData, size: size)
  }

  @MainActor
  @available(*, deprecated, message: "Use svg(_:size:) instead.")
  public init(svgString: String, size: CGSize) throws {
    self = try Image.svg(svgString, size: size)
  }

  @available(*, deprecated, message: "Use svg(_:size:scale:) instead.")
  public init(svgData: Data, size: CGSize, scale: CGFloat) throws {
    self = try Image.svg(svgData, size: size, scale: scale)
  }

  @available(*, deprecated, message: "Use svg(_:size:scale:) instead.")
  public init(svgString: String, size: CGSize, scale: CGFloat) throws {
    self = try Image.svg(svgString, size: size, scale: scale)
  }
}
