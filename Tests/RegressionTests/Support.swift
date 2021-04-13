import AppKit
import CoreGraphics
import os.log

import Base
import libcggen
import XCTest
import WebKit

private enum Error: Swift.Error {
  case compilationError
  case exitStatusNotZero
  case cgimageCreationFailed
}

extension NSImage {
  func cgimg() throws -> CGImage {
    // Sometimes NSImage.cgImage has different size than underlying cgimage
    if representations.count == 1,
       let repr = representations.first,
       repr.className == "NSCGImageSnapshotRep" {
      return try repr.cgImage(forProposedRect: nil, context: nil, hints: nil) !!
        Error.cgimageCreationFailed
    }
    return try cgImage(forProposedRect: nil, context: nil, hints: nil) !!
      Error.cgimageCreationFailed
  }
}

func readImage(filePath: String) throws -> CGImage {
  enum ReadImageError: Swift.Error {
    case failedToCreateDataProvider
    case failedToCreateImage
  }
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

func compare(_ img1: CGImage, _ img2: CGImage) -> Double {
  let buffer1 = RGBABuffer(image: img1)
  let buffer2 = RGBABuffer(image: img2)

  let rw1 = buffer1.pixels
    .flatMap { $0 }
    .flatMap { $0.norm(Double.self).components }

  let rw2 = buffer2.pixels
    .flatMap { $0 }
    .flatMap { $0.norm(Double.self).components }

  let ziped = zip(rw1, rw2).lazy.map(-)
  return ziped.rootMeanSquare()
}

func getCurentFilePath(_ file: StaticString = #file) -> URL {
  URL(fileURLWithPath: file.description, isDirectory: false)
    .deletingLastPathComponent()
}

func cggen(
  files: [URL],
  scale: Double,
  callerAllowAntialiasing: Bool
) throws -> [CGImage] {
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
  let caller = tmpdir.appendingPathComponent("main.m")
  let genBin = tmpdir.appendingPathComponent("bin")
  let outputPngs = tmpdir.appendingPathComponent("pngs").path

  try testLog.signpostRegion("runCggen") {
    try fm.createDirectory(
      atPath: outputPngs, withIntermediateDirectories: true
    )
    try runCggen(
      with: .init(
        objcHeader: header,
        objcPrefix: "Tests",
        objcImpl: impl.path,
        bytecodeFilePrefix: nil,
        objcHeaderImportPath: header,
        objcCallerPath: caller.path,
        callerScale: scale,
        callerAllowAntialiasing: callerAllowAntialiasing,
        callerPngOutputPath: outputPngs,
        generationStyle: nil,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map { $0.path }
      )
    )
  }
  try testLog.signpostRegion("clang invoc") {
    try clang(out: genBin, files: [impl, caller])
  }

  try testLog.signpostRegion("img gen bin") {
    try checkStatus(bin: genBin)
  }

  let pngPaths = files.map {
    "\(outputPngs)/\($0.deletingPathExtension().lastPathComponent).png"
  }

  return try pngPaths.map(readImage)
}

private func check_output(cmd: String...) throws -> (out: String, err: String) {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  task.arguments = cmd
  let outputPipe = Pipe()
  let errorPipe = Pipe()

  task.standardOutput = outputPipe
  task.standardError = errorPipe
  try task.run()
  let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
  let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(decoding: outputData, as: UTF8.self)
  let error = String(decoding: errorData, as: UTF8.self)
  return (output, error)
}

private let sdkPath = try! check_output(
  cmd: "xcrun", "--sdk", "macosx", "--show-sdk-path"
).out.trimmingCharacters(in: .newlines)

private func subprocess(
  cmd: [String],
  env: [String: String]? = nil
) throws -> Int32 {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  task.arguments = cmd
  task.environment = env ?? ProcessInfo().environment
  try task.run()
  task.waitUntilExit()
  return task.terminationStatus
}

private func clang(out: URL, files: [URL]) throws {
  let clangCode = try subprocess(
    cmd: [
      "clang",
      "-Weverything",
      "-Werror",
      "-fmodules",
      "-isysroot",
      sdkPath,
      "-framework",
      "CoreGraphics",
      "-framework",
      "Foundation",
      "-framework",
      "ImageIO",
      "-framework",
      "CoreServices",
      "-o",
      out.path,
    ] + files.map { $0.path },
    env: [:]
  )
  try check(clangCode == 0, Error.compilationError)
}

private func checkStatus(bin: URL) throws {
  let genCallerCode = try subprocess(cmd: [bin.path])
  try check(genCallerCode == 0, Error.exitStatusNotZero)
}

extension FileManager {
  private func contentsOfDirectory(at url: URL) throws -> [URL] {
    try contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: nil,
      options: []
    )
  }
}

let testLog = OSLog(
  subsystem: "cggen.regression_tests",
  category: .pointsOfInterest
)

internal let signpost = testLog.signpost
internal func signpostRegion<T>(
  _ desc: StaticString,
  _ region: () throws -> T
) rethrows -> T {
  try testLog.signpostRegion(desc, region)
}

internal func test(
  snapshot: (URL) throws -> CGImage,
  adjustImage: (CGImage) -> CGImage = { $0 },
  antialiasing: Bool,
  path: URL,
  tolerance: Double,
  scale: Double,
  size _: CGSize
) throws {
  let referenceImg = try signpostRegion("snapshot") {
    try snapshot(path)
  }

  let images = try cggen(
    files: [path],
    scale: scale,
    callerAllowAntialiasing: antialiasing
  )
  try check(images.count == 1, Err("multiple images from cggen"))
  let image = adjustImage(images[0])
  try check(
    referenceImg.intSize == image.intSize,
    Err("reference image size: \(referenceImg.intSize), got \(image.intSize)")
  )
  let diff = signpostRegion("image comparision") {
    compare(referenceImg, image)
  }

  XCTAssertLessThan(
    diff, tolerance, "Calculated diff exceeds tolerance"
  )
  if diff >= tolerance {
    XCTContext.runActivity(named: "Diff of \(path.lastPathComponent)") {
      $0.add(.init(image: image, name: "result"))
      $0.add(.init(image: referenceImg, name: "webkitsnapshot"))
      $0.add(.init(image: .diff(lhs: referenceImg, rhs: image), name: "diff"))
    }
  }
}

extension XCTAttachment {
  convenience init(image: CGImage, name: String) {
    let size = NSSize(width: image.width, height: image.height)
    let nsimage = NSImage(cgImage: image, size: size)
    self.init(image: nsimage)
    self.name = name
  }
}

struct Err: Swift.Error {
  var description: String

  init(_ desc: String) {
    description = desc
  }
}

func renderPDF(from pdf: URL, scale: CGFloat) throws -> CGImage {
  let pdf = CGPDFDocument(pdf as CFURL)!
  try check(pdf.pages.count == 1, Err("multipage pdf"))
  return try
    pdf.pages[0].render(scale: scale) !! Err("Couldnt create png from \(pdf)")
}

extension WKWebView {
  @NSManaged
  private func _setPageZoomFactor(_: Double)
  @NSManaged
  private func _pageZoomFactor() -> Double

  fileprivate var pageZoomFactor: CGFloat {
    get {
      if #available(macOS 11, *) {
        return pageZoom
      } else {
        return CGFloat(_pageZoomFactor())
      }
    }
    set {
      if #available(macOS 11, *) {
        pageZoom = newValue
      } else {
        _setPageZoomFactor(Double(newValue))
      }
    }
  }
}

class WKWebViewSnapshoter {
  private class WKDelegate: NSObject, WKNavigationDelegate {
    private var onNavigationFinishCallbacks = [() -> Void]()

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
      let callbacks = onNavigationFinishCallbacks
      onNavigationFinishCallbacks.removeAll()
      callbacks.forEach(apply)
    }

    func onNavigationFinish(_ callback: @escaping () -> Void) {
      onNavigationFinishCallbacks.append(callback)
    }
  }

  private let webView = WKWebView()
  private let delegate = WKDelegate()

  init() {
    webView.navigationDelegate = delegate
  }

  func take(
    html: String,
    viewport: CGRect,
    scale: CGFloat
  ) throws -> NSImage {
    enum Error: Swift.Error {
      case unknownSnapshotError
    }
    let contentScale = webView.layer.map(\.contentsScale) ?? 1
    let effectiveScale = scale / contentScale
    let effectiveViewport = viewport.applying(.scale(effectiveScale))
    let origin = effectiveViewport.origin
    let size = modified(effectiveViewport.size) {
      $0.width += origin.x * 2
      $0.height += origin.y * 2
    }
    let frame = CGRect(origin: .zero, size: size)
    webView.frame = frame
    webView.bounds = frame
    webView.pageZoomFactor = scale / contentScale

    let config = WKSnapshotConfiguration()
    config.rect = effectiveViewport

    webView.loadHTMLString(html, baseURL: nil)
    waitCallbackOnMT(delegate.onNavigationFinish)

    let result = waitCallbackOnMT { [webView] completion in
      doAfterNextPresentationUpdate {
        webView.takeSnapshot(with: config) {
          completion(($0, $1))
        }
      }
    }
    return try result.0 !! (result.1 ?? Error.unknownSnapshotError)
  }

  private func doAfterNextPresentationUpdate(
    _ block: @escaping @convention(block) () -> Void
  ) {
    webView.perform(Selector(("_doAfterNextPresentationUpdate:")), with: block)
  }
}

extension WKWebViewSnapshoter {
  func take(sample: URL, scale: CGFloat, size: CGSize) throws -> NSImage {
    try take(
      html: String(contentsOf: sample),
      viewport: CGRect(origin: CGPoint(x: 8, y: 8), size: size),
      scale: scale
    )
  }
}
