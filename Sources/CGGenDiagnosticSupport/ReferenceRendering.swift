import CGGenCLI
import CGGenCore
import CoreGraphics
import Foundation
import ImageIO
@_spi(Testing) import CGGenRTSupport

/// Reference rendering utilities for diagnostic comparison
public enum ReferenceRendering {
  /// Render bytecode to CGImage
  public static func renderBytecode(
    _ bytecode: [UInt8],
    width: Int,
    height: Int,
    scale: CGFloat,
    antialiasing: Bool = true
  ) throws -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: cs,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      throw Err("Failed to create CGContext")
    }

    context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
    context.setAllowsAntialiasing(antialiasing)
    try runBytecode(context, fromData: Data(bytecode))

    guard let image = context.makeImage() else {
      throw Err("Failed to draw CGImage")
    }

    return image
  }

  /// Render PDF page as reference
  public static func renderPDFPage(
    _ page: CGPDFPage,
    scale: CGFloat,
    backgroundColor: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
  ) throws -> CGImage {
    let mediaBox = page.getBoxRect(.mediaBox)
    let width = Int(mediaBox.width * scale)
    let height = Int(mediaBox.height * scale)

    let cs = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: cs,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      throw Err("Failed to create context")
    }

    // Background
    context.setFillColor(backgroundColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Draw PDF
    context.saveGState()
    context.scaleBy(x: scale, y: scale)
    context.drawPDFPage(page)
    context.restoreGState()

    guard let image = context.makeImage() else {
      throw Err("Failed to create image")
    }

    return image
  }

  /// Render SVG using cggen bytecode
  public static func renderSVGWithCGGen(
    from url: URL,
    scale: CGFloat
  ) throws -> CGImage {
    let (bytecode, size) = try getImageBytecode(from: url)
    return try renderBytecode(
      bytecode,
      width: Int(size.width * scale),
      height: Int(size.height * scale),
      scale: scale
    )
  }

  /// Render PDF using cggen bytecode
  public static func renderPDFWithCGGen(
    from url: URL,
    scale: CGFloat
  ) throws -> CGImage {
    let (bytecode, size) = try getImageBytecode(from: url)
    return try renderBytecode(
      bytecode,
      width: Int(size.width * scale),
      height: Int(size.height * scale),
      scale: scale
    )
  }
}

// MARK: - Image Utilities

extension CGImage {
  /// Save image as PNG
  public func savePNG(to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
      url as CFURL,
      "public.png" as CFString,
      1,
      nil
    ) else {
      throw Err("Failed to create image destination")
    }

    CGImageDestinationAddImage(destination, self, nil)

    guard CGImageDestinationFinalize(destination) else {
      throw Err("Failed to save image")
    }
  }
}
