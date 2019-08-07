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
  let parser = ArgParser(
    helptext: "Tool for generationg CoreGraphics code from vector images in pdf format",
    version: "0.1"
  )
  let firstImagePathKey = "first-image"
  let secondImagePathKey = "second-image"
  let imageDiffOutputKey = "output-image-diff"
  let asciiDiffOutputKey = "output-ascii-diff"
  parser.newString(firstImagePathKey)
  parser.newString(secondImagePathKey)
  parser.newString(imageDiffOutputKey)
  parser.newString(asciiDiffOutputKey)
  parser.parse()
  return Args(
    firstImagePath: parser.string(at: firstImagePathKey)!,
    secondImagePath: parser.string(at: secondImagePathKey)!,
    imageDiffOutput: parser.string(at: imageDiffOutputKey),
    asciiDiffOutput: parser.string(at: asciiDiffOutputKey)
  )
}

enum ReadImageError: Error {
  case failedToCreateDataProvider
  case failedToCreateImage
}

func readImage(filePath: String) throws -> CGImage {
  let url = URL(fileURLWithPath: filePath) as CFURL
  guard let dataProvider = CGDataProvider(url: url)
  else { throw ReadImageError.failedToCreateDataProvider }
  guard let img = CGImage(
    pngDataProviderSource: dataProvider,
    decode: nil,
    shouldInterpolate: true,
    intent: .defaultIntent
  )
  else { throw ReadImageError.failedToCreateImage }
  return img
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

  let buffer1 = RGBABuffer(image: img1)
  let buffer2 = RGBABuffer(image: img2)

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
