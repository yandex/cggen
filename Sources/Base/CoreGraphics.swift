// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import CoreGraphics
import CoreServices
import ImageIO

public typealias RGBAPixel = RGBAColor<UInt8>

extension RGBAPixel {
  public init<T: Sequence>(
    bufferPiece: T
  ) where T.Element == UInt8 {
    var it = bufferPiece.makeIterator()
    red = it.next()!
    green = it.next()!
    blue = it.next()!
    alpha = it.next()!
  }
}

public class RGBABuffer {
  public let size: CGIntSize
  public typealias BufferPieces = Splitted<UnsafeBufferPointer<UInt8>>
  public typealias SlicedBufferPieces = Slice<BufferPieces>
  public typealias Pixelated<T: Collection> = LazyMapCollection<T, RGBAPixel>
  public typealias Lines = Splitted<Pixelated<BufferPieces>>

  public let pixels: LazyMapSequence<Lines, Pixelated<SlicedBufferPieces>>

  private let free: () -> Void

  public init(image: CGImage) {
    let ctx = CGContext.bitmapRGBContext(size: image.intSize)
    ctx.draw(image, in: image.intSize.rect)
    let raw = ctx.data!.assumingMemoryBound(to: UInt8.self)
    let size = image.intSize
    let bytesPerRow = ctx.bytesPerRow
    let length = size.height * bytesPerRow
    let pixelsPerRow = bytesPerRow / 4
    let buffer = UnsafeBufferPointer(start: raw, count: length)
    free = { withExtendedLifetime(ctx) { _ in } }
    pixels = buffer
      .splitBy(subSize: 4)
      .lazy
      .map(RGBAPixel.init)
      .splitBy(subSize: pixelsPerRow)
      .lazy
      .map { $0.dropLast(pixelsPerRow - size.width) }
    self.size = size
  }

  deinit {
    free()
  }
}

// Geometry

public struct CGIntSize: Equatable {
  public let width: Int
  public let height: Int

  @inlinable
  public init(width: Int, height: Int) {
    self.width = width
    self.height = height
  }

  @inlinable
  public static func size(w: Int, h: Int) -> CGIntSize {
    CGIntSize(width: w, height: h)
  }

  @inlinable
  public var rect: CGRect {
    CGRect(x: 0, y: 0, width: width, height: height)
  }

  @inlinable
  public static func from(cgsize: CGSize) -> CGIntSize {
    CGIntSize(width: Int(cgsize.width), height: Int(cgsize.height))
  }

  @inlinable
  public static func union(lhs: CGIntSize, rhs: CGIntSize) -> CGIntSize {
    CGIntSize(
      width: max(lhs.width, rhs.width),
      height: max(lhs.height, rhs.height)
    )
  }
}

extension CGRect {
  @inlinable
  public var x: CGFloat {
    origin.x
  }

  @inlinable
  public var y: CGFloat {
    origin.y
  }
}

extension CGSize {
  @inlinable
  public static func square(_ dim: CGFloat) -> CGSize {
    .init(width: dim, height: dim)
  }
}

extension CGPoint {
  @inlinable
  public static func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint {
    .init(x: lhs * rhs.x, y: lhs * rhs.y)
  }

  @inlinable
  public static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }

  @inlinable
  public func reflected(across p: CGPoint) -> CGPoint {
    2 * p - self
  }
}

extension CGAffineTransform {
  @inlinable
  public static func scale(_ scale: CGFloat) -> CGAffineTransform {
    CGAffineTransform(scaleX: scale, y: scale)
  }

  @inlinable
  public static func invertYAxis(height: CGFloat) -> CGAffineTransform {
    CGAffineTransform(scaleX: 1, y: -1).concatenating(.init(translationX: 0, y: height))
  }
}

extension Double {
  public var cgfloat: CGFloat {
    CGFloat(self)
  }
}

// PDF

extension CGPDFDocument {
  public var pages: [CGPDFPage] {
    (1...numberOfPages).compactMap(page(at:))
  }
}

extension CGPDFPage {
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

extension CGColorSpace {
  public static var deviceRGB: CGColorSpace {
    CGColorSpaceCreateDeviceRGB()
  }
}

// Context

extension CGContext {
  public static func bitmapRGBContext(size: CGSize) -> CGContext {
    bitmapRGBContext(size: .from(cgsize: size))
  }

  public static func bitmapRGBContext(size: CGIntSize) -> CGContext {
    CGContext(
      data: nil,
      width: size.width,
      height: size.height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: .deviceRGB,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
  }
}

// Image

extension CGImage {
  public var intSize: CGIntSize {
    .size(w: width, h: height)
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

  public func redraw(with background: CGColor) -> CGImage {
    let size = intSize
    let ctx = CGContext.bitmapRGBContext(size: size)
    ctx.setFillColor(background)
    ctx.fill(size.rect)
    ctx.draw(self, in: size.rect)
    return ctx.makeImage()!
  }
}

extension CGPath {
  public static func make(_ builder: (CGMutablePath) -> Void) -> CGPath {
    let mutable = CGMutablePath()
    builder(mutable)
    return mutable.copy()!
  }
}
