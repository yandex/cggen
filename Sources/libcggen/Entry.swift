import Base
import Foundation
import PDFParse

public struct Args {
  let objcHeader: String?
  let objcPrefix: String?
  let objcImpl: String?
  let objcHeaderImportPath: String?
  let objcCallerPath: String?
  let callerScale: Double
  let callerPngOutputPath: String?
  let generationStyle: String?
  let cggenSupportHeaderPath: String?
  let module: String?
  let importAsModules: Bool
  let verbose: Bool
  let files: [String]

  public init(
    objcHeader: String?,
    objcPrefix: String?,
    objcImpl: String?,
    objcHeaderImportPath: String?,
    objcCallerPath: String?,
    callerScale: Double,
    callerPngOutputPath: String?,
    generationStyle: String?,
    cggenSupportHeaderPath: String?,
    module: String?,
    importAsModules: Bool,
    verbose: Bool,
    files: [String]
  ) {
    self.objcHeader = objcHeader
    self.objcPrefix = objcPrefix
    self.objcImpl = objcImpl
    self.objcHeaderImportPath = objcHeaderImportPath
    self.objcCallerPath = objcCallerPath
    self.callerScale = callerScale
    self.callerPngOutputPath = callerPngOutputPath
    self.generationStyle = generationStyle
    self.cggenSupportHeaderPath = cggenSupportHeaderPath
    self.module = module
    self.importAsModules = importAsModules
    self.verbose = verbose
    self.files = files
  }
}

public func runCggen(with args: Args) {
  Logger.shared.setLevel(level: args.verbose)
  var stopwatch = StopWatch()

  let images = args.files
    .map { URL(fileURLWithPath: $0) }
    .concurrentMap { (
      $0.deletingPathExtension().lastPathComponent,
      PDFParser.parse(pdfURL: $0 as CFURL)
    ) }
    .flatMap { nameAndRoutes in
      nameAndRoutes.1.enumerated().compactMap { (offset, page) -> Image in
        let finalName = nameAndRoutes.0 + (offset == 0 ? "" : "_\(offset)")
        let route = PDFToDrawRouteConverter.convert(page: page)
        return Image(name: finalName, route: route)
      }
    }
  log("Parsed in: \(stopwatch.reset())")
  let objcPrefix = args.objcPrefix ?? ""
  let style = args.generationStyle.flatMap(GenerationParams.Style.init(rawValue:)) ?? .plain
  let params = GenerationParams(
    style: style,
    importAsModules: args.importAsModules,
    prefix: objcPrefix,
    module: args.module ?? ""
  )

  if let objcHeaderPath = args.objcHeader {
    let headerGenerator = ObjcHeaderCGGenerator(params: params)
    let fileStr = headerGenerator.generateFile(images: images)
    try! fileStr.write(toFile: objcHeaderPath, atomically: true, encoding: .utf8)
    log("Header generated in: \(stopwatch.reset())")
  }

  if let objcImplPath = args.objcImpl {
    let headerImportPath = args.objcHeaderImportPath
    let implGenerator = ObjcCGGenerator(
      params: params,
      headerImportPath: headerImportPath
    )
    let fileStr = implGenerator.generateFile(images: images)
    try! fileStr.write(toFile: objcImplPath, atomically: true, encoding: .utf8)
    log("Impl generated in: \(stopwatch.reset())")
  }

  if case .swiftFriendly = params.style, let path = args.cggenSupportHeaderPath {
    try! params.cggenSupportHeaderBody.renderText()
      .write(toFile: path, atomically: true, encoding: .utf8)
    log("cggen_support was generated in: \(stopwatch.reset())")
  }

  if let objcCallerPath = args.objcCallerPath,
    let pngOutputPath = args.callerPngOutputPath,
    let headerImportPath = args.objcHeaderImportPath {
    let callerGenerator = ObjcCallerGen(
      headerImportPath: headerImportPath,
      scale: args.callerScale.cgfloat,
      prefix: objcPrefix,
      outputPath: pngOutputPath
    )
    let fileStr = callerGenerator.generateFile(images: images)
    try! fileStr.write(toFile: objcCallerPath, atomically: true, encoding: .utf8)
    log("Caller generated in: \(stopwatch.reset())")
  }
}
