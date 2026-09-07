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
    size: CGSize? = nil,
    scale: CGFloat = 1.0
  ) throws -> CGImage {
    try SVGRenderer.createCGImage(from: data, size: size, scale: scale)
  }

  /// Creates a CGImage from SVG string
  public static func svg(
    _ string: String,
    size: CGSize? = nil,
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
  public static func svg(
    _ data: Data,
    size: CGSize
  ) throws -> CGGenPlatformImage {
    #if canImport(UIKit)
    let scale = UIScreen.main.scale
    #elseif canImport(AppKit)
    let scale = NSScreen.main?.backingScaleFactor ?? 1.0
    #endif
    return try svg(data, size: size, scale: scale)
  }

  @MainActor
  public static func svg(
    _ string: String,
    size: CGSize
  ) throws -> CGGenPlatformImage {
    #if canImport(UIKit)
    let scale = UIScreen.main.scale
    #elseif canImport(AppKit)
    let scale = NSScreen.main?.backingScaleFactor ?? 1.0
    #endif
    return try svg(string, size: size, scale: scale)
  }

  // MARK: Methods with explicit scale

  public static func svg(
    _ data: Data,
    size: CGSize,
    scale: CGFloat
  ) throws -> CGGenPlatformImage {
    let cgImage = try CGImage.svg(data, size: size, scale: scale)
    #if canImport(UIKit)
    return CGGenPlatformImage(cgImage: cgImage, scale: scale, orientation: .up)
    #elseif canImport(AppKit)
    return CGGenPlatformImage(cgImage: cgImage, size: size)
    #endif
  }

  public static func svg(
    _ string: String,
    size: CGSize,
    scale: CGFloat
  ) throws -> CGGenPlatformImage {
    guard let data = string.data(using: .utf8) else {
      throw SVGRenderer.Error.invalidUTF8String
    }
    return try svg(data, size: size, scale: scale)
  }
}

// MARK: - SwiftUI Image SVG Support

extension Image {
  @MainActor
  public static func svg(_ data: Data, size: CGSize) throws -> Image {
    let image = try CGGenPlatformImage.svg(data, size: size)
    #if canImport(UIKit)
    return Image(uiImage: image)
    #elseif canImport(AppKit)
    return Image(nsImage: image)
    #endif
  }

  @MainActor
  public static func svg(_ string: String, size: CGSize) throws -> Image {
    let image = try CGGenPlatformImage.svg(string, size: size)
    #if canImport(UIKit)
    return Image(uiImage: image)
    #elseif canImport(AppKit)
    return Image(nsImage: image)
    #endif
  }

  public static func svg(
    _ data: Data,
    size: CGSize,
    scale: CGFloat
  ) throws -> Image {
    let image = try CGGenPlatformImage.svg(
      data,
      size: size,
      scale: scale
    )
    #if canImport(UIKit)
    return Image(uiImage: image)
    #elseif canImport(AppKit)
    return Image(nsImage: image)
    #endif
  }

  public static func svg(
    _ string: String,
    size: CGSize,
    scale: CGFloat
  ) throws -> Image {
    let image = try CGGenPlatformImage.svg(
      string,
      size: size,
      scale: scale
    )
    #if canImport(UIKit)
    return Image(uiImage: image)
    #elseif canImport(AppKit)
    return Image(nsImage: image)
    #endif
  }
}
