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

  @MainActor
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
    Drawing.circle.draw(in: context)

    print("  ⬜ Drawing.square → \(Drawing.square.size)")
    Drawing.square.draw(in: context)

    print("  ⭐ Drawing.star → \(Drawing.star.size)")
    Drawing.star.draw(in: context)

    print("\n✨ All shapes rendered using optimized bytecode!")

    print("\n=== 🎨 Image Factories ===")

    // Platform-specific image creation
    #if canImport(UIKit)
    print("\n📱 iOS UIImage Creation:")
    let circleImage = UIImage.draw(.circle)
    print("  • UIImage.draw(.circle) → size: \(circleImage.size)")

    let squareImage = UIImage.draw(.square)
    print("  • UIImage.draw(.square) → size: \(squareImage.size)")

    let starImage = UIImage.draw(.star, scale: 2.0)
    print("  • UIImage.draw(.star, scale: 2.0) → size: \(starImage.size)")
    #elseif canImport(AppKit)
    print("\n🖥️  macOS NSImage Creation:")
    let circleImage = NSImage.draw(.circle)
    print("  • NSImage.draw(.circle) → size: \(circleImage.size)")

    let squareImage = NSImage.draw(.square)
    print("  • NSImage.draw(.square) → size: \(squareImage.size)")

    let starImage = NSImage.draw(.star, scale: 2.0)
    print("  • NSImage.draw(.star, scale: 2.0) → size: \(starImage.size)")
    #endif

    // Core Graphics direct drawing
    print("\n🎯 Core Graphics Direct Drawing:")
    if let cgImage = CGImage.draw(from: Drawing.circle, scale: 1.0) {
      print(
        "  • CGImage from Drawing.circle: \(cgImage.width)×\(cgImage.height)px"
      )
    }

    // Show alternative direct Drawing syntax
    print("\n📝 Alternative Direct Drawing Syntax:")
    #if canImport(UIKit)
    let altImage = UIImage.draw(.star)
    print("  • UIImage.draw(.star) → size: \(altImage.size)")
    #elseif canImport(AppKit)
    let altImage = NSImage.draw(.star)
    print("  • NSImage.draw(.star) → size: \(altImage.size)")
    #endif

    // Demonstrate content mode API
    print("\n🎨 Content Mode API Examples:")
    let targetSize = CGSize(width: 100, height: 100)

    #if canImport(UIKit)
    let aspectFitImage = UIImage.draw(
      .circle,
      size: targetSize,
      contentMode: .aspectFit
    )
    print("  • Aspect Fit (100×100): \(aspectFitImage.size)")

    let aspectFillImage = UIImage.draw(
      .star,
      size: targetSize,
      contentMode: .aspectFill
    )
    print("  • Aspect Fill (100×100): \(aspectFillImage.size)")

    let scaleToFillImage = UIImage.draw(
      .square,
      size: CGSize(width: 150, height: 75),
      contentMode: .scaleToFill
    )
    print("  • Scale to Fill (150×75): \(scaleToFillImage.size)")
    #elseif canImport(AppKit)
    let aspectFitImage = NSImage.draw(
      .circle,
      size: targetSize,
      contentMode: .aspectFit
    )
    print("  • Aspect Fit (100×100): \(aspectFitImage.size)")

    let aspectFillImage = NSImage.draw(
      .star,
      size: targetSize,
      contentMode: .aspectFill
    )
    print("  • Aspect Fill (100×100): \(aspectFillImage.size)")

    let scaleToFillImage = NSImage.draw(
      .square,
      size: CGSize(width: 150, height: 75),
      contentMode: .scaleToFill
    )
    print("  • Scale to Fill (150×75): \(scaleToFillImage.size)")
    #endif
  }

  public static func demonstratePathExtraction() {
    print("\n📍 Path Extraction:")

    let starPath = CGMutablePath()
    Drawing.Path.simpleStar.apply(to: starPath)
    print("  • Drawing.Path.simpleStar → \(starPath.boundingBox)")

    let heartPath = CGMutablePath()
    Drawing.Path.simpleHeart.apply(to: heartPath)
    print("  • Drawing.Path.simpleHeart → \(heartPath.boundingBox)")

    let arrowPath = CGMutablePath()
    Drawing.Path.simpleArrow.apply(to: arrowPath)
    print("  • Drawing.Path.simpleArrow → \(arrowPath.boundingBox)")
  }

  public static func main() {
    Task { @MainActor in
      demonstrateGeneratedCode()
      demonstratePathExtraction()

      // Keep the process alive to see output
      print("\n✅ Demo completed!")
    }

    // Wait for async task to complete
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
  }
}
