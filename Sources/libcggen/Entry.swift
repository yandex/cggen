import Foundation

import Base
import PDFParse

public struct Args {
  let objcHeader: String?
  let objcPrefix: String?
  let objcImpl: String?
  let objcHeaderImportPath: String?
  let objcCallerPath: String?
  let callerScale: Double
  let callerAllowAntialiasing: Bool
  let callerPngOutputPath: String?
  let generationStyle: GenerationStyle
  let cggenSupportHeaderPath: String?
  let module: String?
  let verbose: Bool
  let files: [String]

  public init(
    objcHeader: String?,
    objcPrefix: String?,
    objcImpl: String?,
    objcHeaderImportPath: String?,
    objcCallerPath: String?,
    callerScale: Double,
    callerAllowAntialiasing: Bool = false,
    callerPngOutputPath: String?,
    generationStyle: GenerationStyle,
    cggenSupportHeaderPath: String?,
    module: String?,
    verbose: Bool,
    files: [String]
  ) {
    self.objcHeader = objcHeader
    self.objcPrefix = objcPrefix
    self.objcImpl = objcImpl
    self.objcHeaderImportPath = objcHeaderImportPath
    self.objcCallerPath = objcCallerPath
    self.callerScale = callerScale
    self.callerAllowAntialiasing = callerAllowAntialiasing
    self.callerPngOutputPath = callerPngOutputPath
    self.generationStyle = generationStyle
    self.cggenSupportHeaderPath = cggenSupportHeaderPath
    self.module = module
    self.verbose = verbose
    self.files = files
  }
}

public func runCggen(with args: Args) throws {
  Logger.shared.setLevel(level: args.verbose)
  var stopwatch = StopWatch()
  let files = args.files.map(URL.init(fileURLWithPath:))
  let images = try generateImages(from: files)

  log("Parsed in: \(stopwatch.reset())")
  let objcPrefix = args.objcPrefix ?? ""
  let style = args.generationStyle
  let params = GenerationParams(
    style: style,
    prefix: objcPrefix,
    module: args.module ?? ""
  )

  if let objcHeaderPath = args.objcHeader {
    let headerGenerator = ObjcHeaderCGGenerator(params: params)
    let fileStr = headerGenerator.generateFile(images: images)
    try fileStr.write(
      toFile: objcHeaderPath,
      atomically: true,
      encoding: .utf8
    )
    log("Header generated in: \(stopwatch.reset())")
  }

  if let objcImplPath = args.objcImpl {
    let implGenerator = BCCGGenerator(
      params: params,
      headerImportPath: args.objcHeaderImportPath
    )
    let fileStr = implGenerator.generateFile(images: images)
    try fileStr.write(
      toFile: objcImplPath,
      atomically: true,
      encoding: .utf8
    )

    log("Bytecode generated in: \(stopwatch.reset())")
  }

  if case .swiftFriendly = params.style,
     let path = args.cggenSupportHeaderPath {
    try params.cggenSupportHeaderBody.renderText()
      .write(toFile: path, atomically: true, encoding: .utf8)
    log("cggen_support was generated in: \(stopwatch.reset())")
  }

  if let objcCallerPath = args.objcCallerPath,
     let pngOutputPath = args.callerPngOutputPath,
     let headerImportPath = args.objcHeaderImportPath {
    let callerGenerator = ObjcCallerGen(
      headerImportPath: headerImportPath,
      scale: args.callerScale.cgfloat,
      allowAntialiasing: args.callerAllowAntialiasing,
      prefix: objcPrefix,
      outputPath: pngOutputPath
    )
    let fileStr = callerGenerator.generateFile(images: images)
    try fileStr.write(
      toFile: objcCallerPath,
      atomically: true,
      encoding: .utf8
    )
    log("Caller generated in: \(stopwatch.reset())")
  }
}

public enum Error: Swift.Error {
  case unsupportedFileExtension(String)
  case multiplePagedPdfNotSupported(file: String)
  case imageGenerationFailed([(URL, Swift.Error)])
}

private typealias Generator = (URL) throws -> DrawRoute

private let generator: Generator = {
  switch $0.pathExtension {
  case "pdf":
    let pages = try PDFParser.parse(pdfURL: $0 as CFURL)
    try check(
      pages.count == 1,
      Error.multiplePagedPdfNotSupported(file: $0.absoluteString)
    )
    return try PDFToDrawRouteConverter.convert(page: pages[0])
  case "svg":
    let svg = try SVGParser.root(from: Data(contentsOf: $0))
    return try SVGToDrawRouteConverter.convert(document: svg)
  case let ext:
    throw Error.unsupportedFileExtension(ext)
  }
}

private func generateImages(
  from files: [URL],
  generator: Generator = generator
) throws -> [Image] {
  let generator: (URL) -> Result<DrawRoute, Swift.Error> = { url in
    Result(catching: { try generator(url) })
  }

  let generated = zip(files, files.concurrentMap(generator))

  let failed = generated.compactMap { (url, result) -> (URL, Swift.Error)? in
    switch result {
    case .success:
      return nil
    case let .failure(error):
      return (url, error)
    }
  }

  guard failed.isEmpty else {
    throw Error.imageGenerationFailed(failed)
  }

  return generated.map {
    Image(
      name: $0.0.deletingPathExtension().lastPathComponent,
      route: try! $0.1.get()
    )
  }
}

public func getBytecode(from file: URL) throws -> [UInt8] {
  let img = try generateImages(from: [file])[0]
  return generateRouteBytecode(route: img.route)
}
