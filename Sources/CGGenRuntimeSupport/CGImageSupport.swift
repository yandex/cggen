import CoreGraphics
import Foundation

// MARK: - SwiftUI Support

#if canImport(SwiftUI)
import SwiftUI

extension Drawing: View {
  public var body: some View {
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      Canvas { context, canvasSize in
        context.withCGContext { cgContext in
          // Calculate scale to fit the canvas
          let scaleX = canvasSize.width / size.width
          let scaleY = canvasSize.height / size.height
          let scale = min(scaleX, scaleY)

          // Center the drawing
          let scaledWidth = size.width * scale
          let scaledHeight = size.height * scale
          let offsetX = (canvasSize.width - scaledWidth) / 2
          let offsetY = (canvasSize.height - scaledHeight) / 2

          // Flip the coordinate system to match UIKit/AppKit
          cgContext.translateBy(x: 0, y: canvasSize.height)
          cgContext.scaleBy(x: 1, y: -1)

          // Apply centering and scaling
          cgContext.translateBy(x: offsetX, y: offsetY)
          cgContext.scaleBy(x: scale, y: scale)

          draw(in: cgContext)
        }
      }
      .aspectRatio(size, contentMode: .fit)
    } else {
      Image(drawing: self)
        .renderingMode(.original)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }
}
#endif

extension CGImage {
  public static func draw(
    from descriptor: Drawing,
    scale: CGFloat,
    colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
  ) -> CGImage? {
    let size = descriptor.size
    let scaledSize = CGSize(
      width: size.width * scale,
      height: size.height * scale
    )

    let bytesPerRow = Int(scaledSize.width) * 4
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
      data: nil,
      width: Int(scaledSize.width),
      height: Int(scaledSize.height),
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      return nil
    }

    if scale != 1.0 {
      context.scaleBy(x: scale, y: scale)
    }

    descriptor.draw(in: context)

    return context.makeImage()
  }
}

extension CGContext {
  public func draw(
    _ descriptor: Drawing,
    at origin: CGPoint = .zero
  ) {
    saveGState()
    defer { restoreGState() }

    translateBy(x: origin.x, y: origin.y)
    descriptor.draw(in: self)
  }
}
