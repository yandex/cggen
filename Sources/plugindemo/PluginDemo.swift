import CGGenRuntimeSupport
import CoreGraphics
import Foundation

public enum PluginDemo {
  public static func createTestContext() -> CGContext? {
    CGContext(
      data: nil,
      width: 200,
      height: 200,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  }

  public static func demonstrateGeneratedCode() {
    print("PluginDemo: Testing auto-generated Swift code from SVG files")

    guard let context = createTestContext() else {
      print("Failed to create graphics context")
      return
    }

    print(
      "Created graphics context with size: \(context.width)x\(context.height)"
    )

    // Use the auto-generated drawing functions from our SVG files!
    print("\n=== Drawing Circle ===")
    print("Size: \(plugindemocircle.size)")
    plugindemocircle.draw(context)
    print("Circle drawn successfully!")

    print("\n=== Drawing Square ===")
    print("Size: \(plugindemosquare.size)")
    plugindemosquare.draw(context)
    print("Square drawn successfully!")

    print("\n=== Drawing Star ===")
    print("Size: \(plugindemostar.size)")
    plugindemostar.draw(context)
    print("Star drawn successfully!")

    print(
      "\n🎉 All shapes drawn using auto-generated Swift code from SVG files!"
    )
    print(
      "The plugin successfully converted 3 SVG files to optimized Swift drawing functions."
    )

    // Demonstrate the new image utilities
    print("\n=== Image Creation Utilities ===")

    if let cgImage = CGImage.draw(from: plugindemocircle) {
      print(
        "✅ Created CGImage from circle descriptor (size: \(cgImage.width)x\(cgImage.height))"
      )
    }

    if let cgImageScaled = CGImage.draw(from: plugindemostar, scale: 2.0) {
      print(
        "✅ Created 2x scaled CGImage from star descriptor (size: \(cgImageScaled.width)x\(cgImageScaled.height))"
      )
    }

    #if canImport(UIKit)
    let uiImage = UIImage(plugindemosquare)
    print("✅ Created UIImage from square descriptor (size: \(uiImage.size))")
    #endif
  }
}
