import Foundation
import BCCommon

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
  let shouldMergeBytecode: Bool

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
    files: [String],
    shouldMergeBytecode: Bool
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
    self.shouldMergeBytecode = shouldMergeBytecode
  }
}

public func runCggen(with args: Args) throws {
  Logger.shared.setLevel(level: args.verbose)
  var stopwatch = StopWatch()
  let files = args.files.map(URL.init(fileURLWithPath:))
  let outputs = try generateImagesAndPaths(from: files)

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
    let fileStr = try headerGenerator.generateFile(outputs: outputs)
    try fileStr.write(
      toFile: objcHeaderPath,
      atomically: true,
      encoding: .utf8
    )
    log("Header generated in: \(stopwatch.reset())")
  }

  if let objcImplPath = args.objcImpl {
    var implGenerator: CoreGraphicsGenerator {
      if #available(macOS 10.15, *), args.shouldMergeBytecode {
        return MBCCGGenerator(params: params, headerImportPath: args.objcHeaderImportPath)
      } else {
        return BCCGGenerator(params: params, headerImportPath: args.objcHeaderImportPath)
      }
    }

    let fileStr = try implGenerator.generateFile(outputs: outputs)
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
    let fileStr = try callerGenerator.generateFile(outputs: outputs)
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

private typealias Generator = (URL) throws -> Routines

private let pdfAndSvgGenerator: Generator = {
  switch $0.pathExtension {
  case "pdf":
    let pages = try PDFParser.parse(pdfURL: $0 as CFURL)
    try check(
      pages.count == 1,
      Error.multiplePagedPdfNotSupported(file: $0.absoluteString)
    )
    return try Routines(
      drawRoutine: PDFToDrawRouteConverter
        .convert(page: pages[0])
    )
  case "svg":
    let svg = try SVGParser.root(from: Data(contentsOf: $0))
    return try SVGToDrawRouteConverter.convert(document: svg)
  case let ext:
    throw Error.unsupportedFileExtension(ext)
  }
}

func flattenDrawSteps(_ steps: [DrawStep]) -> [DrawStep] {
  steps.flatMap { step -> [DrawStep] in
    guard case let .composite(substeps) = step else { return [step] }
    return flattenDrawSteps(substeps)
  }
}

private func flattenDrawRoute(from generator: @escaping Generator)
  -> Generator {
  { url in
    var routines = try generator(url)
    routines.drawRoutine.steps = flattenDrawSteps(routines.drawRoutine.steps)
    routines.drawRoutine.subroutines = routines.drawRoutine.subroutines
      .mapValues { modified($0) {
        $0.steps = flattenDrawSteps($0.steps)
      }}
    return routines
  }
}

private let generator = flattenDrawRoute(from: pdfAndSvgGenerator)

private func generateImagesAndPaths(
  from files: [URL],
  generator: @escaping Generator = generator
) throws -> [Output] {
  let generator: (URL) -> Result<Routines, Swift.Error> = { url in
    Result(catching: { try generator(url) })
  }

  let generated = zip(files, files.concurrentMap(generator))

  let failed = generated.compactMap { url, result -> (URL, Swift.Error)? in
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

  return try generated.map {
    let image = Image(
      name: $0.0.deletingPathExtension().lastPathComponent,
      route: try $0.1.get().drawRoutine
    )

    let pathRoutines = try $0.1.get().pathRoutines
    return Output(image: image, pathRoutines: pathRoutines)
  }
}

public func getImageBytecode(from file: URL) throws -> [UInt8] {
  let img = try generateImagesAndPaths(from: [file])[0]
  return generateRouteBytecode(route: img.image.route)
}

public func getPathBytecode(from file: URL) throws -> [UInt8] {
  let img = try generateImagesAndPaths(from: [file])[0]
  return generatePathBytecode(route: img.pathRoutines[0])
}

@available(macOS 10.15, *)
public func getImagesMergedBytecodeAndPositions(
  from files: [URL]
) throws -> ([UInt8], [(Int, Int)], Int) {
  let images = try generateImagesAndPaths(from: files).map(\.image)

  var imagePossitions: [(Int, Int)] = []
  var mergedBytecodes: [UInt8] = []

  images.forEach { image in
    let bytecode = generateRouteBytecode(route: image.route)

    imagePossitions.append((mergedBytecodes.count, mergedBytecodes.count + bytecode.count - 1))
    mergedBytecodes += bytecode
  }

  return (try compressBytecode(mergedBytecodes), imagePossitions, mergedBytecodes.count)
}
