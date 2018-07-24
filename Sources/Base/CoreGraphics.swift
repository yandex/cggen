// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import CoreGraphics
import CoreServices
import ImageIO

// Geometry

public struct CGIntSize: Equatable {
  public let width: Int
  public let height: Int
  public static func size(w: Int, h: Int) -> CGIntSize {
    return CGIntSize(width: w, height: h)
  }

  public var rect: CGRect {
    return CGRect(x: 0, y: 0, width: width, height: height)
  }

  public static func from(cgsize: CGSize) -> CGIntSize {
    return CGIntSize(width: Int(cgsize.width), height: Int(cgsize.height))
  }

  public static func union(lhs: CGIntSize, rhs: CGIntSize) -> CGIntSize {
    return CGIntSize(width: max(lhs.width, rhs.width),
                     height: max(lhs.height, rhs.height))
  }
}

public extension CGRect {
  public var x: CGFloat {
    return origin.x
  }

  public var y: CGFloat {
    return origin.y
  }
}

public extension CGAffineTransform {
  public static func scale(_ scale: CGFloat) -> CGAffineTransform {
    return CGAffineTransform(scaleX: scale, y: scale)
  }
}

extension Double {
  public var cgfloat: CGFloat {
    return CGFloat(self)
  }
}

// PDF

public extension CGPDFDocument {
  public var pages: [CGPDFPage] {
    return (1...numberOfPages).compactMap(page(at:))
  }
}

public extension CGPDFPage {
  public func render(scale: CGFloat) -> CGImage? {
    let s = getBoxRect(.mediaBox).size
    let ctxSize = s.applying(.scale(scale))
    let ctx = CGContext.bitmapRGBContext(size: ctxSize)
    ctx.setAllowsAntialiasing(false)
    ctx.scaleBy(x: scale, y: scale)
    ctx.drawPDFPage(self)
    return ctx.makeImage()
  }
}

// Color space

public extension CGColorSpace {
  public static var deviceRGB: CGColorSpace {
    return CGColorSpaceCreateDeviceRGB()
  }
}

// Context

extension CGContext {
  public static func bitmapRGBContext(size: CGSize) -> CGContext {
    return bitmapRGBContext(size: .from(cgsize: size))
  }

  public static func bitmapRGBContext(size: CGIntSize) -> CGContext {
    return CGContext(data: nil,
                     width: size.width,
                     height: size.height,
                     bitsPerComponent: 8,
                     bytesPerRow: 0,
                     space: .deviceRGB,
                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  }
}

// Color

extension CGColor {
  public static var white: CGColor {
    return CGColor(red: 1, green: 1, blue: 1, alpha: 1)
  }
}

// Image

public extension CGImage {
  public var intSize: CGIntSize {
    return .size(w: width, h: height)
  }

  public static func diff(lhs: CGImage, rhs: CGImage) -> CGImage {
    let size = CGIntSize.union(lhs: lhs.intSize, rhs: rhs.intSize)
    let ctx = CGContext.bitmapRGBContext(size: size)
    ctx.draw(lhs, in: lhs.intSize.rect)
    ctx.setAlpha(0.5)
    ctx.setBlendMode(.difference)
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.draw(rhs, in: rhs.intSize.rect)
    ctx.setFillColor(.white)
    ctx.endTransparencyLayer()
    return ctx.makeImage()!
  }

  public enum CGImageWriteError: Error {
    case failedToCreateDestination
    case failedDestinationFinalize
  }

  public func write(fileURL: CFURL) throws {
    guard let destination = CGImageDestinationCreateWithURL(fileURL, kUTTypePNG, 1, nil)
    else { throw CGImageWriteError.failedDestinationFinalize }
    CGImageDestinationAddImage(destination, self, nil)
    guard CGImageDestinationFinalize(destination)
    else { throw CGImageWriteError.failedDestinationFinalize }
  }
}
