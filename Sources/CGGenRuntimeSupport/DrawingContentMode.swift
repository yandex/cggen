import CoreGraphics

// MARK: - Content Mode Support

public enum DrawingContentMode {
  case scaleToFill
  case aspectFit
  case aspectFill
  case center
  case top
  case bottom
  case left
  case right
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
}

extension CGImage {
  public static func draw(
    from descriptor: Drawing,
    targetSize: CGSize,
    contentMode: DrawingContentMode,
    scale: CGFloat = 1.0,
    colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
  ) -> CGImage? {
    let sourceSize = descriptor.size
    let scaledTargetSize = CGSize(
      width: targetSize.width * scale,
      height: targetSize.height * scale
    )
    
    let bytesPerRow = Int(scaledTargetSize.width) * 4
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    
    guard let context = CGContext(
      data: nil,
      width: Int(scaledTargetSize.width),
      height: Int(scaledTargetSize.height),
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      return nil
    }
    
    // Apply scale factor
    context.scaleBy(x: scale, y: scale)
    
    // Calculate transform based on content mode
    let transform = calculateTransform(
      sourceSize: sourceSize,
      targetSize: targetSize,
      contentMode: contentMode
    )
    
    // Apply transform and draw
    context.saveGState()
    context.translateBy(x: transform.translation.x, y: transform.translation.y)
    context.scaleBy(x: transform.scale.width, y: transform.scale.height)
    descriptor.draw(context)
    context.restoreGState()
    
    return context.makeImage()
  }
  
  private static func calculateTransform(
    sourceSize: CGSize,
    targetSize: CGSize,
    contentMode: DrawingContentMode
  ) -> (translation: CGPoint, scale: CGSize) {
    switch contentMode {
    case .scaleToFill:
      return (
        translation: .zero,
        scale: CGSize(
          width: targetSize.width / sourceSize.width,
          height: targetSize.height / sourceSize.height
        )
      )
      
    case .aspectFit:
      let scale = min(
        targetSize.width / sourceSize.width,
        targetSize.height / sourceSize.height
      )
      let scaledSize = CGSize(
        width: sourceSize.width * scale,
        height: sourceSize.height * scale
      )
      return (
        translation: CGPoint(
          x: (targetSize.width - scaledSize.width) / 2,
          y: (targetSize.height - scaledSize.height) / 2
        ),
        scale: CGSize(width: scale, height: scale)
      )
      
    case .aspectFill:
      let scale = max(
        targetSize.width / sourceSize.width,
        targetSize.height / sourceSize.height
      )
      let scaledSize = CGSize(
        width: sourceSize.width * scale,
        height: sourceSize.height * scale
      )
      return (
        translation: CGPoint(
          x: (targetSize.width - scaledSize.width) / 2,
          y: (targetSize.height - scaledSize.height) / 2
        ),
        scale: CGSize(width: scale, height: scale)
      )
      
    case .center:
      return (
        translation: CGPoint(
          x: (targetSize.width - sourceSize.width) / 2,
          y: (targetSize.height - sourceSize.height) / 2
        ),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .top:
      return (
        translation: CGPoint(
          x: (targetSize.width - sourceSize.width) / 2,
          y: targetSize.height - sourceSize.height
        ),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .bottom:
      return (
        translation: CGPoint(
          x: (targetSize.width - sourceSize.width) / 2,
          y: 0
        ),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .left:
      return (
        translation: CGPoint(
          x: 0,
          y: (targetSize.height - sourceSize.height) / 2
        ),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .right:
      return (
        translation: CGPoint(
          x: targetSize.width - sourceSize.width,
          y: (targetSize.height - sourceSize.height) / 2
        ),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .topLeft:
      return (
        translation: CGPoint(x: 0, y: targetSize.height - sourceSize.height),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .topRight:
      return (
        translation: CGPoint(
          x: targetSize.width - sourceSize.width,
          y: targetSize.height - sourceSize.height
        ),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .bottomLeft:
      return (
        translation: CGPoint(x: 0, y: 0),
        scale: CGSize(width: 1, height: 1)
      )
      
    case .bottomRight:
      return (
        translation: CGPoint(
          x: targetSize.width - sourceSize.width,
          y: 0
        ),
        scale: CGSize(width: 1, height: 1)
      )
    }
  }
}