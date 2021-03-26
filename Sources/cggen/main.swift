import Foundation
import ArgumentParser
import libcggen
import Base

struct Main: ParsableCommand {

  @Option var objcHeader: String?
  @Option var objcPrefix = ""
  @Option var objcImpl: String?
  @Option var objcHeaderImportPath: String?
  @Option var objcCallerPath: String?
  @Option var callerScale = 1.0
  @Option var callerPngOutputPath: String?
  @Option var generationStyle: String?
  @Option var cggenSupportHeaderPath: String?
  @Option var module = ""
  @Flag var verbose = false
  @Flag var callerAllowAntialiasing = false
  @Argument var files: [String]

  public static let configuration = CommandConfiguration(
    commandName: "cggen",
    abstract: "Tool for generationg CoreGraphics code from vector images in pdf format",
    version: "0.1"
  )

  public mutating func run() throws {
    Logger.shared.setLevel(level: verbose)
    var stopwatch = StopWatch()
    let files = self.files.map(URL.init(fileURLWithPath:))
    let images = try generateImages(from: files)

    log("Parsed in: \(stopwatch.reset())")
    let style = generationStyle.flatMap(GenerationParams.Style.init(rawValue:)) ?? .plain
    let params = GenerationParams(
      style: style,
      prefix: objcPrefix,
      module: module
    )

    if let objcHeaderPath = objcHeader {
      let headerGenerator = ObjcHeaderCGGenerator(params: params)
      let fileStr = headerGenerator.generateFile(images: images)
      try! fileStr.write(toFile: objcHeaderPath, atomically: true, encoding: .utf8)
      log("Header generated in: \(stopwatch.reset())")
    }

    if let objcImplPath = objcImpl {
      let headerImportPath = objcHeaderImportPath
      let implGenerator = ObjcCGGenerator(
        params: params,
        headerImportPath: headerImportPath
      )
      let fileStr = implGenerator.generateFile(images: images)
      try! fileStr.write(toFile: objcImplPath, atomically: true, encoding: .utf8)
      log("Impl generated in: \(stopwatch.reset())")
    }

    if case .swiftFriendly = params.style, let path = cggenSupportHeaderPath {
      try! params.cggenSupportHeaderBody.renderText()
        .write(toFile: path, atomically: true, encoding: .utf8)
      log("cggen_support was generated in: \(stopwatch.reset())")
    }

    if let objcCallerPath = objcCallerPath,
       let pngOutputPath = callerPngOutputPath,
       let headerImportPath = objcHeaderImportPath {
      let callerGenerator = ObjcCallerGen(
        headerImportPath: headerImportPath,
        scale: callerScale.cgfloat,
        allowAntialiasing: callerAllowAntialiasing,
        prefix: objcPrefix,
        outputPath: pngOutputPath
      )
      let fileStr = callerGenerator.generateFile(images: images)
      try! fileStr.write(toFile: objcCallerPath, atomically: true, encoding: .utf8)
      log("Caller generated in: \(stopwatch.reset())")
    }
  }
}

Main.main()