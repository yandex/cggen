// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import ArgParse
import Base
import Foundation

struct Args {
  let firstImagePath: String
  let secondImagePath: String
  let imageDiffOutput: String?
  let asciiDiffOutput: String?
}

func ParseArgs() -> Args {
  let parser = ArgParser(helptext: "Tool for generationg CoreGraphics code from vector images in pdf format",
                         version: "0.1")
  let firstImagePathKey = "first-image"
  let secondImagePathKey = "second-image"
  let imageDiffOutputKey = "output-image-diff"
  let asciiDiffOutputKey = "output-ascii-diff"
  parser.newString(firstImagePathKey)
  parser.newString(secondImagePathKey)
  parser.newString(imageDiffOutputKey)
  parser.newString(asciiDiffOutputKey)
  parser.parse()
  return Args(firstImagePath: parser.string(at: firstImagePathKey)!,
              secondImagePath: parser.string(at: secondImagePathKey)!,
              imageDiffOutput: parser.string(at: imageDiffOutputKey),
              asciiDiffOutput: parser.string(at: asciiDiffOutputKey))
}

enum ReadImageError: Error {
  case failedToCreateDataProvider
  case failedToCreateImage
}

func readImage(filePath: String) throws -> CGImage {
  let url = URL(fileURLWithPath: filePath) as CFURL
  guard let dataProvider = CGDataProvider(url: url)
  else { throw ReadImageError.failedToCreateDataProvider }
  guard let img = CGImage(pngDataProviderSource: dataProvider,
                          decode: nil,
                          shouldInterpolate: true,
                          intent: .defaultIntent)
  else { throw ReadImageError.failedToCreateImage }
  return img
}

struct RGBAPixel: Equatable {
  let red: UInt8
  let green: UInt8
  let blue: UInt8
  let alpha: UInt8
  init(bufferPiece: [UInt8]) {
    precondition(bufferPiece.count == 4)
    red = bufferPiece[0]
    green = bufferPiece[1]
    blue = bufferPiece[2]
    alpha = bufferPiece[3]
  }

  var components: [UInt8] {
    return [red, green, blue, alpha]
  }

  var componentsNormalized: [Double] {
    return components.map { Double($0) / Double(UInt8.max) }
  }

  var squaredSum: Double {
    return componentsNormalized.map({ $0 * $0 }).reduce(0, +)
  }

  static func ==(lhs: RGBAPixel, rhs: RGBAPixel) -> Bool {
    return lhs.components == rhs.components
  }
}

struct RGBABuffer: Equatable {
  static func ==(lhs: RGBABuffer, rhs: RGBABuffer) -> Bool {
    return lhs.size == rhs.size && lhs.pixels.elementsEqual(rhs.pixels, by: ==)
  }

  let size: CGIntSize
  let pixels: [[RGBAPixel]]

  init(raw: UnsafePointer<UInt8>, size: CGIntSize, bytesPerRow: Int) {
    let length = size.height * bytesPerRow
    let buffer = UnsafeBufferPointer(start: raw, count: length)
    pixels = Array(buffer)
      .splitBy(subSize: 4)
      .map { RGBAPixel(bufferPiece: $0) }
      .splitBy(subSize: bytesPerRow / 4)
      .map { Array($0.dropLast(bytesPerRow / 4 - size.width)) }
    self.size = size
  }
}

extension CGImage {
  func rgbaBuffer() -> RGBABuffer {
    let ctx = CGContext.bitmapRGBContext(size: intSize)
    ctx.draw(self, in: intSize.rect)
    let data = ctx.data!.assumingMemoryBound(to: UInt8.self)
    return RGBABuffer(raw: data, size: intSize, bytesPerRow: ctx.bytesPerRow)
  }
}

func symbolForRelativeDeviation(_ deviation: Double) -> String {
  precondition(0...1 ~= deviation)
  switch deviation {
  case ..<0.001:
    return " "
  case ..<0.01:
    return "·"
  case ..<0.1:
    return "•"
  case ..<0.2:
    return "✜"
  case ..<0.3:
    return "✖"
  default:
    return "@"
  }
}

func asciiDiff(buffer1: RGBABuffer, buffer2: RGBABuffer) -> String {
  return zip(buffer1.pixels, buffer2.pixels)
    .concurrentMap { l1, l2 in zip(l1, l2)
      .map { p1, p2 in
        let deviation = zip(p1.componentsNormalized, p2.componentsNormalized)
          .map(-)
          .rootMeanSquare()
        return symbolForRelativeDeviation(deviation)
      }
      .joined()
    }
    .joined(separator: "\n")
}

func main(args: Args) -> Int32 {
  let img1 = try! readImage(filePath: args.firstImagePath)
  let img2 = try! readImage(filePath: args.secondImagePath)

  if let diffOutputImage = args.imageDiffOutput {
    let url = URL(fileURLWithPath: diffOutputImage) as CFURL
    try! CGImage.diff(lhs: img1, rhs: img2).write(fileURL: url)
  }

  let buffer1 = img1.rgbaBuffer()
  let buffer2 = img2.rgbaBuffer()

  if let diffOutputAscii = args.asciiDiffOutput {
    let url = URL(fileURLWithPath: diffOutputAscii)
    try! asciiDiff(buffer1: buffer1, buffer2: buffer2)
      .data(using: .utf8)!
      .write(to: url)
  }

  let rw1 = buffer1.pixels
    .flatMap { $0 }
    .flatMap { $0.componentsNormalized }

  let rw2 = buffer2.pixels
    .flatMap { $0 }
    .flatMap { $0.componentsNormalized }

  let ziped = zip(rw1, rw2).lazy.map(-)
  print(ziped.rootMeanSquare())
  return 0
}

exit(main(args: ParseArgs()))
