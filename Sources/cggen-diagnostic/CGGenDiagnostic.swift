import ArgumentParser
import CGGenCLI
import CGGenCore
import CGGenDiagnosticSupport
import CoreGraphics
import Foundation

@main
struct CGGenDiagnostic: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "cggen-diagnostic",
    abstract: "Diagnose rendering differences between cggen and reference implementations",
    discussion: """
    Renders SVG/PDF files using both cggen's bytecode and reference implementations
    to identify rendering differences. For SVG files, uses WebKit as reference.
    For PDF files, uses CoreGraphics as reference.
    """
  )

  @Argument(help: "Path to the SVG or PDF file to diagnose")
  var inputFile: String

  @Option(name: .shortAndLong, help: "Rendering scale factor (default: 2.0)")
  var scale: Double = 2.0

  @Option(name: .long, help: "Pixel difference tolerance (default: 0.002)")
  var tolerance: Double = 0.002

  @Option(name: .shortAndLong, help: "Output directory for diagnostic images")
  var output: String?

  @Flag(name: .shortAndLong, help: "Verbose diagnostic output")
  var verbose: Bool = false

  @MainActor
  mutating func run() async throws {
    let url = URL(fileURLWithPath: inputFile)

    print("🔍 Diagnosing: \(url.lastPathComponent)")

    if url.pathExtension.lowercased() == "svg" {
      try await diagnoseSVG(at: url)
    } else if url.pathExtension.lowercased() == "pdf" {
      try diagnosePDF(at: url)
    } else {
      throw ValidationError("Unsupported file type. Use .svg or .pdf")
    }
  }

  @MainActor
  private func diagnoseSVG(at url: URL) async throws {
    // Step 1: Render with cggen
    let cggenImage = try ReferenceRendering.renderSVGWithCGGen(
      from: url,
      scale: CGFloat(scale)
    )
    print("✅ cggen rendering: \(cggenImage.width)×\(cggenImage.height) px")

    // Step 2: Render reference with WebKit
    print("📋 Rendering reference with WebKit...")
    let svgData = try Data(contentsOf: url)
    let svgString = String(data: svgData, encoding: .utf8) ?? ""

    let webkit = WebKitSVG2PNG()
    let referenceImage = try await webkit.convertToCGImage(
      svg: svgString,
      scale: CGFloat(scale)
    )
    print(
      "✅ Reference rendering: \(referenceImage.width)×\(referenceImage.height) px"
    )

    // Step 3: Compare
    let difference = ImageComparison.compare(referenceImage, cggenImage)

    print("\n📊 Comparison Results:")
    print("   Difference: \(String(format: "%.6f", difference))")
    print("   Tolerance: \(tolerance)")
    print("   Status: \(difference < tolerance ? "✅ PASS" : "❌ FAIL")")

    if verbose, difference >= tolerance {
      print("\n⚠️  Images differ beyond tolerance threshold")
    }

    // Save diagnostic images if requested
    if let outputDir = output {
      let dir = URL(fileURLWithPath: outputDir)
      try FileManager.default.createDirectory(
        at: dir,
        withIntermediateDirectories: true
      )

      let basename = url.deletingPathExtension().lastPathComponent
      try referenceImage
        .savePNG(to: dir.appendingPathComponent("\(basename)-reference.png"))
      try cggenImage
        .savePNG(to: dir.appendingPathComponent("\(basename)-cggen.png"))

      let diffImage = CGImage.diff(lhs: referenceImage, rhs: cggenImage)
      try diffImage
        .savePNG(to: dir.appendingPathComponent("\(basename)-diff.png"))

      print("\n💾 Diagnostic images saved to: \(outputDir)")
    }
  }

  private func diagnosePDF(at url: URL) throws {
    guard let pdf = CGPDFDocument(url as CFURL),
          pdf.numberOfPages == 1,
          let page = pdf.page(at: 1) else {
      throw ValidationError("Failed to load PDF or multi-page PDF not supported"
      )
    }

    // Step 1: Render with cggen
    let cggenImage = try ReferenceRendering.renderPDFWithCGGen(
      from: url,
      scale: CGFloat(scale)
    )
    print("✅ cggen rendering: \(cggenImage.width)×\(cggenImage.height) px")

    // Step 2: Render reference with CoreGraphics
    let referenceImage = try ReferenceRendering.renderPDFPage(
      page,
      scale: CGFloat(scale)
    )
    print(
      "✅ Reference rendering: \(referenceImage.width)×\(referenceImage.height) px"
    )

    // Step 3: Compare
    let difference = ImageComparison.compare(referenceImage, cggenImage)

    print("\n📊 Comparison Results:")
    print("   Difference: \(String(format: "%.6f", difference))")
    print("   Tolerance: \(tolerance)")
    print("   Status: \(difference < tolerance ? "✅ PASS" : "❌ FAIL")")

    // Save diagnostic images if requested
    if let outputDir = output {
      let dir = URL(fileURLWithPath: outputDir)
      try FileManager.default.createDirectory(
        at: dir,
        withIntermediateDirectories: true
      )

      let basename = url.deletingPathExtension().lastPathComponent
      try referenceImage
        .savePNG(to: dir.appendingPathComponent("\(basename)-reference.png"))
      try cggenImage
        .savePNG(to: dir.appendingPathComponent("\(basename)-cggen.png"))

      let diffImage = CGImage.diff(lhs: referenceImage, rhs: cggenImage)
      try diffImage
        .savePNG(to: dir.appendingPathComponent("\(basename)-diff.png"))

      print("\n💾 Diagnostic images saved to: \(outputDir)")
    }
  }
}
