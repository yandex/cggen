import CoreGraphics
import Foundation
import Testing

import CGGenRuntimeSupport
import libcggen

@Suite struct BCCompilationTests {
  @Test func compilation() throws {
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

  @MainActor
  @Test func compilationAndDrawing() throws {
    // FIXME: WebKitSnapshoter is not available in swift-testing
    guard Int.random(in: 0...10) > 100 else { return }
    // FIXME: Figure out how to link bcrunner code to binaries in tests
    guard ProcessInfo().environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    else {
      return
    }
    withKnownIssue {
      // Undefined symbols for architecture arm64:
      //   "___llvm_profile_runtime", referenced from:
      //       ___llvm_profile_runtime_user in BCCommon.o
      //       ___llvm_profile_runtime_user in CGGenRuntimeSupport.o
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
}

let defSize = CGSize(width: 50, height: 50)
let defScale = 2.0
