import AppKit
import CoreGraphics
import Foundation
import Testing

import CGGenCLI
import CGGenRTSupport

@Suite struct BCCompilationTests {
  @Test func compilation() throws {
    let variousFilenamesDir =
      getCurrentFilePath().appendingPathComponent("various_filenames")
    let files = [
      "Capital letter.svg",
      "dash-dash.svg",
      "under_score.svg",
      "white space.svg",
    ]

    let fm = FileManager.default

    let tmpdir = try fm.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: fm.homeDirectoryForCurrentUser,
      create: true
    )
    defer {
      do {
        try fm.removeItem(at: tmpdir)
      } catch {
        fatalError("Unable to clean up dir: \(tmpdir), error: \(error)")
      }
    }

    let header = tmpdir.appendingPathComponent("gen.h").path
    let impl = tmpdir.appendingPathComponent("gen.m")

    try runCggen(
      with: .init(
        objcHeader: header,
        objcPrefix: "Tests",
        objcImpl: impl.path,
        objcHeaderImportPath: header,
        objcCallerPath: nil,
        callerScale: 1,
        callerAllowAntialiasing: false,
        callerPngOutputPath: nil,
        generationStyle: .plain,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files
          .map { variousFilenamesDir.appendingPathComponent($0).path },
        swiftOutput: nil
      )
    )

    try clang(
      out: nil,
      files: [impl],
      syntaxOnly: true,
      frameworks: []
    )
  }

  @Test func compilationAndDrawing() throws {
    // FIXME: Figure out how to link bcrunner code to binaries in tests
    guard ProcessInfo().environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    else {
      return
    }

    let testCases: [SVGTestCase] = [
      .caps_joins,
      .clip_path,
      .dashes,
      .shadow_blur_radius,
      .fill,
      .gradient,
      .lines,
      .shapes,
      .transforms,
    ]

    let svgSamplesPath = getCurrentFilePath()
      .appendingPathComponent("svg_samples")
    let files = testCases.map { testCase in
      svgSamplesPath.appendingPathComponent(testCase.rawValue)
        .appendingPathExtension("svg")
    }

    // Load reference images from disk snapshots
    let snapshotsPath = getCurrentFilePath()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent("SVGTests")

    var referenceImages: [CGImage] = []
    for testCase in testCases {
      let snapshotName = "webkit-references.\(testCase.rawValue).png"
      let snapshotPath = snapshotsPath.appendingPathComponent(snapshotName)
      let reference = try readImage(filePath: snapshotPath.path)
      referenceImages.append(reference)
    }

    // Generate images using cggen
    let generatedImages = try cggen(
      files: files,
      scale: defScale,
      callerAllowAntialiasing: true
    ).map { $0.redraw(with: .white) }

    // Compare images
    #expect(generatedImages.count == referenceImages.count)

    for (i, testCase) in testCases.enumerated() {
      let generated = generatedImages[i]
      let reference = referenceImages[i]

      #expect(
        reference.intSize == generated.intSize,
        "\(testCase.rawValue): size mismatch"
      )

      let diff = compare(reference, generated)
      let tolerance = testCase.rawValue == "shadow_blur_radius" ? 0.022 : 0.002
      #expect(
        diff < tolerance,
        "\(testCase.rawValue): difference \(diff) exceeds tolerance \(tolerance)"
      )
    }
  }
}

let defSize = CGSize(width: 50, height: 50)
let defScale = 2.0
