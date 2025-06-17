import CoreGraphics
import ImageIO
import Testing
import UniformTypeIdentifiers

import Base
import CGGenRuntime

@Suite struct SVGRuntimeRenderingTests {
  @Test("SVG Runtime Rendering", arguments: [
    // Gradients
    "gradient.svg",
    "gradient_radial.svg",
    "gradient_with_alpha.svg",
    "gradient_shape.svg",
    "gradient_three_dots.svg",

    // Shapes
    "shapes.svg",
    "path_circle_commands.svg",
    "path_relative_commands.svg",
    "path_short_commands.svg",

    // Styles
    "alpha.svg",
    "caps_joins.svg",
    "dashes.svg",
    "group_opacity.svg",
    "fill.svg",
    "lines.svg",

    // Transforms
    "transforms.svg",
    "gradient_transform_linear.svg",
    "gradient_transform_radial.svg",

    // Special cases
    "use_tag.svg",
    "clip_path.svg",
    "colornames.svg",
    "nested_transparent_group.svg",
    "path_fill_rule.svg",
  ])
  func svgRuntimeRendering(svgFile: String) throws {
    let svgURL = getCurentFilePath()
      .appendingPathComponent("svg_samples")
      .appendingPathComponent(svgFile)

    let svgData = try Data(contentsOf: svgURL)

    // Render using CGGenRuntime
    let runtimeImage = try CGImage.svg(
      svgData,
      size: CGSize(width: 200, height: 200),
      scale: 2.0
    )

    // Get expected snapshot
    let snapshotPath = getCurentFilePath()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent("SVGRuntimeRenderingTests")
      .appendingPathComponent(svgFile.replacingOccurrences(
        of: ".svg",
        with: ".png"
      ))

    let fm = FileManager.default

    // Create snapshot directory if needed
    try fm.createDirectory(
      at: snapshotPath.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    if fm.fileExists(atPath: snapshotPath.path) {
      // Compare with existing snapshot
      let expectedImage = try readImage(filePath: snapshotPath.path)
      let diff = compare(expectedImage, runtimeImage)

      #expect(
        diff < 0.002,
        "SVG runtime rendering differs from snapshot for \(svgFile)"
      )

      if diff >= 0.002 {
        // Write actual output for debugging
        let actualPath = snapshotPath
          .deletingPathExtension()
          .appendingPathExtension("actual")
          .appendingPathExtension("png")

        try writePNG(runtimeImage, to: actualPath)
      }
    } else {
      // Create new snapshot
      try writePNG(runtimeImage, to: snapshotPath)
      Issue
        .record(
          "Created new snapshot for \(svgFile). Please verify the image is correct."
        )
    }
  }

  private func writePNG(_ image: CGImage, to url: URL) throws {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
      data: nil,
      width: image.width,
      height: image.height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      throw Err("Failed to create context for PNG writing")
    }

    context.draw(
      image,
      in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
    )

    guard let outputImage = context.makeImage() else {
      throw Err("Failed to create output image")
    }

    guard let destination = CGImageDestinationCreateWithURL(
      url as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    ) else {
      throw Err("Failed to create image destination")
    }

    CGImageDestinationAddImage(destination, outputImage, nil)

    guard CGImageDestinationFinalize(destination) else {
      throw Err("Failed to finalize image")
    }
  }
}
