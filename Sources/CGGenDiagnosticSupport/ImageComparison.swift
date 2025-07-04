import CGGenCore
import CoreGraphics
import Foundation

/// Image comparison utilities for diagnostic support
public enum ImageComparison {
  /// Compare two images and return the root mean square difference
  /// Returns a value between 0.0 (identical) and higher values for more
  /// different images
  @_optimize(speed)
  public static func compare(_ img1: CGImage, _ img2: CGImage) -> Double {
    let buffer1 = RGBABuffer(image: img1)
    let buffer2 = RGBABuffer(image: img2)

    let rw1 = buffer1.pixels
      .flatMap(\.self)
      .flatMap { $0.norm(Double.self).components }

    let rw2 = buffer2.pixels
      .flatMap(\.self)
      .flatMap { $0.norm(Double.self).components }

    let ziped = zip(rw1, rw2).lazy.map(-)
    return ziped.rootMeanSquare()
  }
}
