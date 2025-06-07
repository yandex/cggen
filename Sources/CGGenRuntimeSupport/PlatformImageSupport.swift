import CoreGraphics

// MARK: - UIKit

#if canImport(UIKit)
import SwiftUI
import UIKit

extension UIImage {
  public convenience init(
    drawing: Drawing,
    scale: CGFloat = UIScreen.main.scale
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
    scale: CGFloat = UIScreen.main.scale
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
  
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat = UIScreen.main.scale
  ) -> UIImage {
    UIImage(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }
  
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat = UIScreen.main.scale
  ) -> UIImage {
    UIImage(
      drawing: Drawing.self[keyPath: keyPath],
      size: size,
      contentMode: contentMode,
      scale: scale
    )
  }
}

extension Image {
  public init(drawing: Drawing, scale: CGFloat = 1.0) {
    let uiImage = UIImage(drawing: drawing, scale: scale)
    self.init(uiImage: uiImage)
  }
  
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat = 1.0
  ) -> Image {
    Image(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }
}

public typealias __CGGenPlatformImage = UIImage

#endif // canImport(UIKit)

// MARK: - AppKit

#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import SwiftUI

extension NSImage {
  public convenience init(
    drawing: Drawing,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
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
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
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
  
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
  ) -> NSImage {
    NSImage(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }
  
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    size: CGSize,
    contentMode: DrawingContentMode = .aspectFit,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
  ) -> NSImage {
    NSImage(
      drawing: Drawing.self[keyPath: keyPath],
      size: size,
      contentMode: contentMode,
      scale: scale
    )
  }
}

extension Image {
  public init(drawing: Drawing, scale: CGFloat = 1.0) {
    if let cgImage = CGImage.draw(from: drawing, scale: scale) {
      self.init(cgImage, scale: scale, label: Text("Generated Image"))
    } else {
      self.init(systemName: "photo")
    }
  }
  
  public static func draw(
    _ keyPath: KeyPath<Drawing.Type, Drawing>,
    scale: CGFloat = 1.0
  ) -> Image {
    Image(drawing: Drawing.self[keyPath: keyPath], scale: scale)
  }
}

public typealias __CGGenPlatformImage = NSImage

#endif // canImport(AppKit) && !canImport(UIKit)
