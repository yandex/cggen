import CoreGraphics
import Foundation
import XCTest

import BCRunner
import libcggen

class BCCompilationTests: XCTestCase {
  func testCompilation() throws {
    let variousFilenamesDir =
      getCurentFilePath().appendingPathComponent("various_filenames")
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
        files: files.map { variousFilenamesDir.appendingPathComponent($0).path },
        shouldMergeBytecode: true
      )
    )

    try clang(
      out: nil,
      files: [impl],
      syntaxOnly: true,
      frameworks: []
    )
  }

  func testCompilationAndDrawing() throws {
    // FIXME: Figure out how to link bcrunner code to binaries in tests
    guard ProcessInfo().environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    else {
      throw XCTSkip("This test supported only in xcode")
    }
    let files = [
      "caps_joins.svg",
      "clip_path.svg",
      "dashes.svg",
      "shadow_blur_radius.svg",
      "fill.svg",
      "gradient.svg",
      "lines.svg",
      "shapes.svg",
      "transforms.svg",
//      "path_smooth_curve_defs.svg",
    ].map { svgSamplesPath.appendingPathComponent($0) }
    try test(
      snapshot: {
        try WKWebViewSnapshoter()
          .take(sample: $0, scale: CGFloat(defScale), size: defSize).cgimg()
      },
      adjustImage: {
        // Unfortunately, snapshot from web view always comes with white
        // background color
        $0.redraw(with: .white)
      },
      antialiasing: true,
      paths: files,
      tolerance: 0.1,
      scale: Double(defScale),
      size: defSize
    )
  }
}

let defSize = CGSize(width: 50, height: 50)
let defScale = 2.0
