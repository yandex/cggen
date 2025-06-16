import Base
@preconcurrency import CoreGraphics
import Foundation
import SVGParse
@_spi(Testing) import CGGenRuntimeSupport

/// Creates CGImage from SVG data
public enum SVGRenderer {
  public enum Error: Swift.Error {
    case invalidSize
    case contextCreationFailed
    case svgParsingFailed
    case renderingFailed
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
    // Validate size
    guard size.width > 0, size.height > 0 else {
      throw Error.invalidSize
    }

    // Parse SVG
    let svg: SVG.Document
    do {
      svg = try SVGParser.root(from: data)
    } catch {
      throw Error.svgParsingFailed
    }

    // Convert to draw routines
    let routines: Routines
    do {
      routines = try SVGToDrawRouteConverter.convert(document: svg)
    } catch {
      throw Error.renderingFailed
    }

    // Calculate scale to fit the SVG into the requested size
    let svgBounds = routines.drawRoutine.boundingRect
    let scaleX = size.width / svgBounds.width
    let scaleY = size.height / svgBounds.height
    let scale = min(scaleX, scaleY)

    // Modify draw routine to include scaling
    var scaledRoutine = routines.drawRoutine
    scaledRoutine.steps = [
      .saveGState,
      .concatCTM(CGAffineTransform(scaleX: scale, y: scale)),
    ] + scaledRoutine.steps + [.restoreGState]

    // Generate bytecode
    let bytecode = generateRouteBytecode(route: scaledRoutine)

    // Create a bitmap context
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

    // Fill with white background
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

    // Execute bytecode to render SVG
    do {
      try runBytecode(context, fromData: Data(bytecode))
    } catch {
      throw Error.renderingFailed
    }

    // Create and return the image
    guard let image = context.makeImage() else {
      throw Error.contextCreationFailed
    }

    return image
  }
}
