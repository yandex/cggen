import CoreGraphics
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Deprecated KeyPath API

extension CGGenPlatformImage {
  @MainActor
  @inlinable
  @available(*, deprecated, renamed: "draw(_:)")
  public static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>)
    -> CGGenPlatformImage {
    CGGenPlatformImage.draw(Drawing.self[keyPath: keyPath])
  }

  @MainActor
  @inlinable
  @available(*, deprecated, renamed: "draw(_:size:contentMode:)")
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit
  ) -> CGGenPlatformImage {
    CGGenPlatformImage.draw(
      Drawing.self[keyPath: keyPath],
      size: size,
      contentMode: contentMode
    )
  }

  @inlinable
  @available(*, deprecated, renamed: "draw(_:scale:)")
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    CGGenPlatformImage.draw(Drawing.self[keyPath: keyPath], scale: scale)
  }

  @inlinable
  @available(*, deprecated, renamed: "draw(_:size:contentMode:scale:)")
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    CGGenPlatformImage.draw(
      Drawing.self[keyPath: keyPath],
      size: size,
      contentMode: contentMode,
      scale: scale
    )
  }
}

extension Image {
  @MainActor
  @inlinable
  @available(*, deprecated, renamed: "draw(_:)")
  public static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>) -> Self {
    draw(Drawing.self[keyPath: keyPath])
  }

  @inlinable
  @available(*, deprecated, renamed: "draw(_:scale:)")
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat
  ) -> Image {
    Image.draw(Drawing.self[keyPath: keyPath], scale: scale)
  }
}

extension CGGenPlatformImage {
  @MainActor
  @available(*, deprecated, message: "Use draw(_:) instead.")
  public convenience init(drawing: Drawing) {
    self.init(drawing: drawing, scale: defaultScale)
  }

  @MainActor
  @available(*, deprecated, message: "Use draw(_:size:contentMode:) instead.")
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
}

extension Image {
  @MainActor
  @available(*, deprecated, message: "Use draw(_:) instead.")
  public init(drawing: Drawing) {
    self = Image.draw(drawing)
  }

  @available(*, deprecated, message: "Use draw(_:scale:) instead.")
  public init(drawing: Drawing, scale: CGFloat) {
    self = Image.draw(drawing, scale: scale)
  }
}

#if canImport(UIKit)
extension UIImage {
  @available(*, deprecated, message: "Use draw(_:scale:) instead.")
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

  @available(
    *,
    deprecated,
    message: "Use draw(_:size:contentMode:scale:) instead."
  )
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
  @available(*, deprecated, renamed: "init(uiImage:)")
  public init(platformImage: UIImage) {
    self.init(uiImage: platformImage)
  }
}

#elseif canImport(AppKit)
extension NSImage {
  @available(*, deprecated, message: "Use draw(_:scale:) instead.")
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

  @available(
    *,
    deprecated,
    message: "Use draw(_:size:contentMode:scale:) instead."
  )
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
  @available(*, deprecated, renamed: "init(nsImage:)")
  public init(platformImage: NSImage) {
    self.init(nsImage: platformImage)
  }
}
#endif
