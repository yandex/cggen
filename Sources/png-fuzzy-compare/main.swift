import Foundation
import Base
import ArgumentParser

struct Main: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "png-fuzzy-compare",
    abstract: "Tool for generationg CoreGraphics code from vector images in pdf format",
    version: "0.1"
  )

  @Option var firstImage: String
  @Option var secondImage: String
  @Option var outputImageDiff: String?
  @Option var outputAsciiDiff: String?

  func run() throws {
    let img1 = try! readImage(filePath: firstImage)
    let img2 = try! readImage(filePath: secondImage)

    if let diffOutputImage = outputImageDiff {
      let url = URL(fileURLWithPath: diffOutputImage) as CFURL
      try! CGImage.diff(lhs: img1, rhs: img2).write(fileURL: url)
    }

    let buffer1 = RGBABuffer(image: img1)
    let buffer2 = RGBABuffer(image: img2)

    if let diffOutputAscii = outputAsciiDiff {
      let url = URL(fileURLWithPath: diffOutputAscii)
      try! asciiDiff(buffer1: buffer1, buffer2: buffer2)
        .data(using: .utf8)!
        .write(to: url)
    }

    let rw1 = buffer1.pixels
      .flatMap { $0 }
      .flatMap { $0.normComponents }

    let rw2 = buffer2.pixels
      .flatMap { $0 }
      .flatMap { $0.normComponents }

    let ziped = zip(rw1, rw2).lazy.map(-)
    print(ziped.rootMeanSquare())
  }
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

extension RGBAPixel {
  var normComponents: [Double] {
    norm().components
  }
}

func asciiDiff(buffer1: RGBABuffer, buffer2: RGBABuffer) -> String {
  zip(buffer1.pixels, buffer2.pixels)
    .concurrentMap { l1, l2 in zip(l1, l2)
      .map { p1, p2 in
        let deviation = zip(p1.normComponents, p2.normComponents)
          .map(-)
          .rootMeanSquare()
        return symbolForRelativeDeviation(deviation)
      }
      .joined()
    }
    .joined(separator: "\n")
}

Main.main()