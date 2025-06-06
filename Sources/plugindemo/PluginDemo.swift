import CoreGraphics
import Foundation
#if canImport(AppKit)
import AppKit
#endif

@main
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
    print("""
    ╔═══════════════════════════════════════════════════════════════╗
    ║                  cggen Plugin Demo                            ║
    ║         SVG → Optimized Swift Code Generation                 ║
    ╚═══════════════════════════════════════════════════════════════╝
    """)

    guard let context = createTestContext() else {
      print("❌ Failed to create graphics context")
      return
    }

    print(
      "✅ Created test context: \(context.width)×\(context.height)px"
    )

    // Direct drawing with generated functions
    print("\n📐 Direct Context Drawing:")
    
    print("  ⭕ Drawing.circle → \(Drawing.circle.size)")
    Drawing.circle.draw(context)
    
    print("  ⬜ Drawing.square → \(Drawing.square.size)")
    Drawing.square.draw(context)
    
    print("  ⭐ Drawing.star → \(Drawing.star.size)")
    Drawing.star.draw(context)

    print("\n✨ All shapes rendered using optimized bytecode!")

    // Demonstrate the preferred KeyPath-based API
    print("\n=== 🎨 Modern Swift API with KeyPaths ===")
    
    // Platform-specific image creation
    #if canImport(UIKit)
    print("\n📱 iOS UIImage Creation (KeyPath API):")
    let circleImage = UIImage.draw(\.circle)
    print("  • UIImage.draw(\\.circle) → size: \(circleImage.size)")
    
    let squareImage = UIImage.draw(\.square)
    print("  • UIImage.draw(\\.square) → size: \(squareImage.size)")
    
    let starImage = UIImage.draw(\.star, scale: 2.0)
    print("  • UIImage.draw(\\.star, scale: 2.0) → size: \(starImage.size)")
    #elseif canImport(AppKit)
    print("\n🖥️  macOS NSImage Creation (KeyPath API):")
    let circleImage = NSImage.draw(\.circle)
    print("  • NSImage.draw(\\.circle) → size: \(circleImage.size)")
    
    let squareImage = NSImage.draw(\.square)
    print("  • NSImage.draw(\\.square) → size: \(squareImage.size)")
    
    let starImage = NSImage.draw(\.star, scale: 2.0)
    print("  • NSImage.draw(\\.star, scale: 2.0) → size: \(starImage.size)")
    #endif
    
    // Core Graphics direct drawing
    print("\n🎯 Core Graphics Direct Drawing:")
    if let cgImage = CGImage.draw(from: Drawing.circle) {
      print("  • CGImage from Drawing.circle: \(cgImage.width)×\(cgImage.height)px")
    }
    
    // Show alternative direct initializer syntax
    print("\n📝 Alternative Direct Initializer (also available):")
    #if canImport(UIKit)
    let altImage = UIImage(drawing: .star)
    print("  • UIImage(drawing: .star) → size: \(altImage.size)")
    #elseif canImport(AppKit)
    let altImage = NSImage(drawing: .star)
    print("  • NSImage(drawing: .star) → size: \(altImage.size)")
    #endif
  }
  
  public static func main() {
    demonstrateGeneratedCode()
  }
}
