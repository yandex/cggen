import CoreGraphics
import SwiftUI

/// A type alias that resolves to the platform's native image type.
/// - On iOS, tvOS, and watchOS: `UIImage`
/// - On macOS: `NSImage`
public typealias CGGenPlatformImage = __CGGenPlatformImage

extension CGGenPlatformImage {
  @MainActor
  public convenience init(drawing: Drawing) {
    self.init(drawing: drawing, scale: defaultScale)
  }

  @MainActor
  public convenience init(
    drawing: Drawing,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit
  ) {
    self.init(
      drawing: drawing,
      size: size,
      contentMode: contentMode,
      scale: defaultScale
    )
  }

  // MARK: Static Factory Methods

  @MainActor
  public static func draw(_ drawing: Drawing) -> CGGenPlatformImage {
    CGGenPlatformImage(drawing: drawing, scale: defaultScale)
  }

  @MainActor
  public static func draw(
    _ drawing: Drawing,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit
  ) -> CGGenPlatformImage {
    CGGenPlatformImage(
      drawing: drawing,
      size: size,
      contentMode: contentMode,
      scale: defaultScale
    )
  }

  public static func draw(
    _ drawing: Drawing,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    CGGenPlatformImage(drawing: drawing, scale: scale)
  }

  public static func draw(
    _ drawing: Drawing,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    CGGenPlatformImage(
      drawing: drawing,
      size: size,
      contentMode: contentMode,
      scale: scale
    )
  }
}

extension Image {
  @MainActor
  public init(drawing: Drawing) {
    self.init(drawing: drawing, scale: defaultScale)
  }

  public init(drawing: Drawing, scale: CGFloat) {
    let image = CGGenPlatformImage(drawing: drawing, scale: scale)
    self.init(platformImage: image)
  }

  // MARK: Static Factory Methods

  @MainActor
  public static func draw(_ drawing: Drawing) -> Image {
    Image(drawing: drawing, scale: defaultScale)
  }

  public static func draw(_ drawing: Drawing, scale: CGFloat) -> Image {
    Image(drawing: drawing, scale: scale)
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
  public convenience init(
    drawing: Drawing,
    scale: CGFloat
  ) {
    if let cgImage = CGImage.draw(from: drawing, scale: scale) {
      self.init(cgImage: cgImage, scale: scale, orientation: .up)
    } else {
      self.init()
    }
  }

  public convenience init(
    drawing: Drawing,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat
  ) {
    if let cgImage = CGImage.draw(
      from: drawing,
      targetSize: size,
      contentMode: contentMode,
      scale: scale
    ) {
      self.init(cgImage: cgImage, scale: scale, orientation: .up)
    } else {
      self.init()
    }
  }
}

extension Image {
  public init(platformImage: UIImage) {
    self.init(uiImage: platformImage)
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
  public convenience init(
    drawing: Drawing,
    scale: CGFloat
  ) {
    if let cgImage = CGImage.draw(from: drawing, scale: scale) {
      self.init(cgImage: cgImage, size: drawing.size)
    } else {
      self.init()
    }
  }

  public convenience init(
    drawing: Drawing,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat
  ) {
    if let cgImage = CGImage.draw(
      from: drawing,
      targetSize: size,
      contentMode: contentMode,
      scale: scale
    ) {
      self.init(cgImage: cgImage, size: size)
    } else {
      self.init()
    }
  }
}

extension Image {
  public init(platformImage: NSImage) {
    self.init(nsImage: platformImage)
  }
}

#endif
