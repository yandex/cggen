import Base
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
  ///   - size: The size to render the SVG at
  /// - Returns: A CGImage containing the rendered SVG
  /// - Throws: Error if SVG parsing or rendering fails
  public static func createCGImage(
    from data: Data,
    size: CGSize
  ) throws -> CGImage {
    guard size.width > 0, size.height > 0 else {
      throw Error.invalidSize
    }

    let svg = try SVGParser.root(from: data)
    let routines = try SVGToDrawRouteConverter.convert(document: svg)

    let svgBounds = routines.drawRoutine.boundingRect
    let scaleX = size.width / svgBounds.width
    let scaleY = size.height / svgBounds.height
    let scale = min(scaleX, scaleY)

    var scaledRoutine = routines.drawRoutine
    scaledRoutine.steps = [
      .saveGState,
      .concatCTM(CGAffineTransform(scaleX: scale, y: scale)),
    ] + scaledRoutine.steps + [.restoreGState]

    let bytecode = generateRouteBytecode(route: scaledRoutine)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
      data: nil,
      width: Int(size.width),
      height: Int(size.height),
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      throw Error.contextCreationFailed
    }

    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

    try runBytecode(context, fromData: Data(bytecode))

    guard let image = context.makeImage() else {
      throw Error.contextCreationFailed
    }

    return image
  }
}
