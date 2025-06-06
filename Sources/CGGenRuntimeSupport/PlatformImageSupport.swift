import CoreGraphics

// MARK: - UIKit

#if canImport(UIKit)
import SwiftUI
import UIKit

extension UIImage {
  public convenience init(
    _ descriptor: CGGenDescriptor,
    scale: CGFloat = UIScreen.main.scale
  ) {
    if let cgImage = CGImage.draw(from: descriptor, scale: scale) {
      self.init(cgImage: cgImage, scale: scale, orientation: .up)
    } else {
      self.init()
    }
  }
}

extension Image {
  public init(_ descriptor: CGGenDescriptor, scale: CGFloat = 1.0) {
    let uiImage = UIImage(descriptor, scale: scale)
    self.init(uiImage: uiImage)
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
    _ descriptor: CGGenDescriptor,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
  ) {
    if let cgImage = CGImage.draw(from: descriptor, scale: scale) {
      self.init(cgImage: cgImage, size: descriptor.size)
    } else {
      self.init()
    }
  }
}

extension Image {
  public init(_ descriptor: CGGenDescriptor, scale: CGFloat = 1.0) {
    if let cgImage = CGImage.draw(from: descriptor, scale: scale) {
      self.init(cgImage, scale: scale, label: Text("Generated Image"))
    } else {
      self.init(systemName: "photo")
    }
  }
}

public typealias __CGGenPlatformImage = NSImage

#endif // canImport(AppKit) && !canImport(UIKit)
