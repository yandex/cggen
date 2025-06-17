import CGGenRTSupport
import CoreGraphics
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - CGImage SVG Support

extension CGImage {
  /// Creates a CGImage from SVG data
  public static func svg(
    _ data: Data,
    size: CGSize,
    scale: CGFloat = 1.0
  ) throws -> CGImage {
    let scaledSize = CGSize(
      width: size.width * scale,
      height: size.height * scale
    )
    return try SVGRenderer.createCGImage(from: data, size: scaledSize)
  }

  /// Creates a CGImage from SVG string
  public static func svg(
    _ string: String,
    size: CGSize,
    scale: CGFloat = 1.0
  ) throws -> CGImage {
    guard let data = string.data(using: .utf8) else {
      throw SVGRenderer.Error.invalidUTF8String
    }
    return try svg(data, size: size, scale: scale)
  }
}

// MARK: - Platform Image SVG Support

extension CGGenPlatformImage {
  // MARK: @MainActor methods using default scale

  @MainActor
  public convenience init(svgData: Data, size: CGSize) throws {
    #if canImport(UIKit)
    let scale = UIScreen.main.scale
    #elseif canImport(AppKit)
    let scale = NSScreen.main?.backingScaleFactor ?? 1.0
    #endif
    try self.init(svgData: svgData, size: size, scale: scale)
  }

  @MainActor
  public convenience init(svgString: String, size: CGSize) throws {
    #if canImport(UIKit)
    let scale = UIScreen.main.scale
    #elseif canImport(AppKit)
    let scale = NSScreen.main?.backingScaleFactor ?? 1.0
    #endif
    try self.init(svgString: svgString, size: size, scale: scale)
  }

  // MARK: Methods with explicit scale

  public convenience init(svgData: Data, size: CGSize, scale: CGFloat) throws {
    let cgImage = try CGImage.svg(svgData, size: size, scale: scale)
    #if canImport(UIKit)
    self.init(cgImage: cgImage, scale: scale, orientation: .up)
    #elseif canImport(AppKit)
    self.init(cgImage: cgImage, size: size)
    #endif
  }

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

// MARK: - SwiftUI Image SVG Support

extension Image {
  @MainActor
  public init(svgData: Data, size: CGSize) throws {
    let image = try CGGenPlatformImage(svgData: svgData, size: size)
    self.init(platformImage: image)
  }

  @MainActor
  public init(svgString: String, size: CGSize) throws {
    let image = try CGGenPlatformImage(svgString: svgString, size: size)
    self.init(platformImage: image)
  }

  public init(svgData: Data, size: CGSize, scale: CGFloat) throws {
    let image = try CGGenPlatformImage(
      svgData: svgData,
      size: size,
      scale: scale
    )
    self.init(platformImage: image)
  }

  public init(svgString: String, size: CGSize, scale: CGFloat) throws {
    let image = try CGGenPlatformImage(
      svgString: svgString,
      size: size,
      scale: scale
    )
    self.init(platformImage: image)
  }
}
