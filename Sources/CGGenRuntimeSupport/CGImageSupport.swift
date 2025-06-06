import CoreGraphics
import Foundation

public typealias CGGenDescriptor = (size: CGSize, draw: (CGContext) -> Void)

extension CGImage {
  public static func draw(
    from descriptor: CGGenDescriptor,
    scale: CGFloat = 1.0,
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

    descriptor.draw(context)

    return context.makeImage()
  }
}

extension CGContext {
  public func draw(
    _ descriptor: CGGenDescriptor,
    at origin: CGPoint = .zero
  ) {
    saveGState()
    defer { restoreGState() }

    translateBy(x: origin.x, y: origin.y)
    descriptor.draw(self)
  }
}
