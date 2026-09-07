import CoreGraphics
import SwiftUI

/// A type alias that resolves to the platform's native image type.
/// - On iOS, tvOS, and watchOS: `UIImage`
/// - On macOS: `NSImage`
public typealias CGGenPlatformImage = __CGGenPlatformImage

extension CGGenPlatformImage {
  // MARK: Static Factory Methods

  @MainActor
  public static func draw(
    _ drawing: Drawing,
    tintColor: CGColor? = nil
  ) -> CGGenPlatformImage {
    CGGenPlatformImage.draw(
      drawing,
      scale: defaultScale,
      tintColor: tintColor
    )
  }

  @MainActor
  public static func draw(
    _ drawing: Drawing,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    tintColor: CGColor? = nil
  ) -> CGGenPlatformImage {
    CGGenPlatformImage.draw(
      drawing,
      size: size,
      contentMode: contentMode,
      scale: defaultScale,
      tintColor: tintColor
    )
  }

  public static func draw(
    _ drawing: Drawing,
    scale: CGFloat,
    tintColor: CGColor? = nil
  ) -> CGGenPlatformImage {
    let cgImage = CGImage.draw(
      from: drawing,
      scale: scale,
      tintColor: tintColor
    )
    return CGGenPlatformImage.platformImage(
      cgImage,
      size: drawing.size,
      scale: scale
    )
  }

  public static func draw(
    _ drawing: Drawing,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat,
    tintColor: CGColor? = nil
  ) -> CGGenPlatformImage {
    let cgImage = CGImage.draw(
      from: drawing,
      targetSize: size,
      contentMode: contentMode,
      scale: scale,
      tintColor: tintColor
    )
    return CGGenPlatformImage.platformImage(
      cgImage,
      size: size,
      scale: scale
    )
  }
}

extension Image {
  // MARK: Static Factory Methods

  @MainActor
  public static func draw(_ drawing: Drawing) -> Image {
    Image.draw(drawing, scale: defaultScale)
  }

  public static func draw(_ drawing: Drawing, scale: CGFloat) -> Image {
    let image = CGGenPlatformImage.draw(drawing, scale: scale)
    #if canImport(UIKit)
    return Image(uiImage: image)
    #elseif canImport(AppKit)
    return Image(nsImage: image)
    #endif
  }
}

#if canImport(UIKit)
import UIKit

public typealias __CGGenPlatformImage = UIImage

@MainActor
@usableFromInline
var defaultScale: CGFloat {
  UIScreen.main.scale
}

extension UIImage {
  fileprivate static func platformImage(
    _ cgImage: CGImage?,
    size _: CGSize,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    guard let cgImage else { return CGGenPlatformImage() }
    return CGGenPlatformImage(
      cgImage: cgImage,
      scale: scale,
      orientation: .up
    )
  }
}

#elseif canImport(AppKit)
import AppKit

public typealias __CGGenPlatformImage = NSImage

@MainActor
@usableFromInline
var defaultScale: CGFloat {
  NSScreen.main?.backingScaleFactor ?? 1.0
}

extension NSImage {
  fileprivate static func platformImage(
    _ cgImage: CGImage?,
    size: CGSize,
    scale _: CGFloat
  ) -> CGGenPlatformImage {
    guard let cgImage else { return CGGenPlatformImage() }
    return CGGenPlatformImage(cgImage: cgImage, size: size)
  }
}

#endif
