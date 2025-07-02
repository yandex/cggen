import CGGenIR
import CGGenRTSupport
@preconcurrency import CoreGraphics
import Foundation
import SVGParse

/// Creates CGImage from SVG data
public enum SVGRenderer {
  public enum Error: Swift.Error {
    case invalidSize
    case contextCreationFailed
    case invalidUTF8String
  }

  /// Create a CGImage from SVG data
  /// - Parameters:
  ///   - data: The SVG content as Data
  ///   - size: The size to render the SVG at. If nil, uses the SVG's natural
  /// size
  ///   - scale: The scale factor to apply
  /// - Returns: A CGImage containing the rendered SVG
  /// - Throws: Error if SVG parsing or rendering fails
  public static func createCGImage(
    from data: Data,
    size: CGSize? = nil,
    scale: CGFloat = 1.0
  ) throws -> CGImage {
    let svg = try SVGParser.root(from: data)
    let routines = try SVGToDrawRouteConverter.convert(document: svg)
    let svgBounds = routines.drawRoutine.boundingRect

    let targetSize: CGSize
    let effectiveScale: CGFloat

    if let size {
      guard size.width > 0, size.height > 0 else {
        throw Error.invalidSize
      }
      targetSize = CGSize(
        width: size.width * scale,
        height: size.height * scale
      )
      let scaleX = size.width / svgBounds.width
      let scaleY = size.height / svgBounds.height
      effectiveScale = min(scaleX, scaleY) * scale
    } else {
      // Use natural size
      targetSize = CGSize(
        width: svgBounds.width * scale,
        height: svgBounds.height * scale
      )
      effectiveScale = scale
    }

    var scaledRoutine = routines.drawRoutine
    if effectiveScale != 1.0 {
      scaledRoutine.steps = [
        .saveGState,
        .concatCTM(CGAffineTransform(
          scaleX: effectiveScale,
          y: effectiveScale
        )),
      ] + scaledRoutine.steps + [.restoreGState]
    }

    let bytecode = generateRouteBytecode(route: scaledRoutine)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
      data: nil,
      width: Int(targetSize.width),
      height: Int(targetSize.height),
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      throw Error.contextCreationFailed
    }

    try runBytecode(context, fromData: Data(bytecode))

    guard let image = context.makeImage() else {
      throw Error.contextCreationFailed
    }

    return image
  }
}
