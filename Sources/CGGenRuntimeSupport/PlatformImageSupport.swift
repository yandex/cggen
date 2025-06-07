import CoreGraphics
import SwiftUI

/// A type alias that resolves to the platform's native image type.
/// - On iOS, tvOS, and watchOS: `UIImage`
/// - On macOS: `NSImage`
public typealias CGGenPlatformImage = __CGGenPlatformImage

extension CGGenPlatformImage {
  // MARK: @MainActor methods using default scale
  
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
    self.init(drawing: drawing, size: size, contentMode: contentMode, scale: defaultScale)
  }
  
  @MainActor
  @inlinable
  public static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>) -> CGGenPlatformImage {
    return CGGenPlatformImage(drawing: Drawing.self[keyPath: keyPath], scale: defaultScale)
  }
  
  @MainActor
  @inlinable
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit
  ) -> CGGenPlatformImage {
    return CGGenPlatformImage(
      drawing: Drawing.self[keyPath: keyPath],
      size: size,
      contentMode: contentMode,
      scale: defaultScale
    )
  }
  
  // MARK: Methods with explicit scale
  
  @inlinable
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    CGGenPlatformImage(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }
  
  @inlinable
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    CGGenPlatformImage(
      drawing: Drawing.self[keyPath: keyPath],
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
  
  @MainActor
  @inlinable
  public static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>) -> Self {
    Self(drawing: Drawing.self[keyPath: keyPath], scale: defaultScale)
  }
  
  public init(drawing: Drawing, scale: CGFloat) {
    let image = CGGenPlatformImage(drawing: drawing, scale: scale)
    self.init(platformImage: image)
  }
  
  @inlinable
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat
  ) -> Image {
    Image(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }
}

#if canImport(UIKit)
import UIKit

public typealias __CGGenPlatformImage = UIImage

@MainActor
@usableFromInline
internal var defaultScale: CGFloat {
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
internal var defaultScale: CGFloat {
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