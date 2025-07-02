import AppKit
import CoreGraphics
import Foundation
import Testing

import CGGenCLI

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
}
