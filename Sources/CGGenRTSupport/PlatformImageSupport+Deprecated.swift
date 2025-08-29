import CoreGraphics
import SwiftUI

// MARK: - Deprecated KeyPath API

extension CGGenPlatformImage {
  @MainActor
  @inlinable
  @available(*, deprecated, renamed: "draw(_:)")
  public static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>)
    -> CGGenPlatformImage {
    CGGenPlatformImage(
      drawing: Drawing.self[keyPath: keyPath],
      scale: defaultScale
    )
  }

  @MainActor
  @inlinable
  @available(*, deprecated, renamed: "draw(_:size:contentMode:)")
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit
  ) -> CGGenPlatformImage {
    CGGenPlatformImage(
      drawing: Drawing.self[keyPath: keyPath],
      size: size,
      contentMode: contentMode,
      scale: defaultScale
    )
  }

  @inlinable
  @available(*, deprecated, renamed: "draw(_:scale:)")
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat
  ) -> CGGenPlatformImage {
    CGGenPlatformImage(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }

  @inlinable
  @available(*, deprecated, renamed: "draw(_:size:contentMode:scale:)")
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
  @inlinable
  @available(*, deprecated, renamed: "draw(_:)")
  public static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>) -> Self {
    Self(drawing: Drawing.self[keyPath: keyPath], scale: defaultScale)
  }

  @inlinable
  @available(*, deprecated, renamed: "draw(_:scale:)")
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat
  ) -> Image {
    Image(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }
}
