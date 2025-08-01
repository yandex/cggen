import Foundation

import CGGenCore
import CGGenIR
import PDFParse
import SVGParse

public struct Args {
  let objcHeader: String?
  let objcPrefix: String?
  let objcImpl: String?
  let objcHeaderImportPath: String?
  let generationStyle: GenerationStyle
  let cggenSupportHeaderPath: String?
  let module: String?
  let verbose: Bool
  let files: [String]
  let swiftOutput: String?

  public init(
    objcHeader: String?,
    objcPrefix: String?,
    objcImpl: String?,
    objcHeaderImportPath: String?,
    generationStyle: GenerationStyle,
    cggenSupportHeaderPath: String?,
    module: String?,
    verbose: Bool,
    files: [String],
    swiftOutput: String?
  ) {
    self.objcHeader = objcHeader
    self.objcPrefix = objcPrefix
    self.objcImpl = objcImpl
    self.objcHeaderImportPath = objcHeaderImportPath
    self.generationStyle = generationStyle
    self.cggenSupportHeaderPath = cggenSupportHeaderPath
    self.module = module
    self.verbose = verbose
    self.files = files
    self.swiftOutput = swiftOutput
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
    let fileStr = generateObjCHeaderFile(
      params: params,
      outputs: outputs
    )
    try fileStr.write(
      toFile: objcHeaderPath,
      atomically: true,
      encoding: .utf8
    )
    log("Header generated in: \(stopwatch.reset())")
  }

  if let objcImplPath = args.objcImpl {
    let fileStr = try generateObjCImplementationFile(
      params: params,
      headerImportPath: args.objcHeaderImportPath,
      outputs: outputs
    )
    try fileStr.write(
      toFile: objcImplPath,
      atomically: true,
      encoding: .utf8
    )

    log("Bytecode generated in: \(stopwatch.reset())")
  }

  if case .swiftFriendly = params.style,
     let path = args.cggenSupportHeaderPath {
    try params.cggenSupportHeaderBody
      .write(toFile: path, atomically: true, encoding: .utf8)
    log("cggen_support was generated in: \(stopwatch.reset())")
  }

  if let swiftOutputPath = args.swiftOutput {
    let fileStr = try generateSwiftFile(
      params: params,
      outputs: outputs
    )
    try fileStr.write(
      toFile: swiftOutputPath,
      atomically: true,
      encoding: .utf8
    )
    log("Swift code generated in: \(stopwatch.reset())")
  }
}

public enum Error: Swift.Error {
  case unsupportedFileExtension(String)
  case multiplePagedPdfNotSupported(file: String)
  case imageGenerationFailed([(URL, Swift.Error)])
}

private typealias Generator = @Sendable (URL) throws -> Routines

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

private func flattenDrawSteps(_ steps: [DrawStep]) -> [DrawStep] {
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
  let generator: @Sendable (URL) -> Result<Routines, Swift.Error> = { url in
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
    let image = try Image(
      name: $0.0.deletingPathExtension().lastPathComponent,
      route: $0.1.get().drawRoutine
    )

    let pathRoutines = try $0.1.get().pathRoutines
    return Output(image: image, pathRoutines: pathRoutines)
  }
}

public func getImageBytecode(from file: URL) throws -> ([UInt8], CGSize) {
  let img = try generateImagesAndPaths(from: [file])[0]
  let bytecode = generateRouteBytecode(route: img.image.route)
  let size = img.image.route.boundingRect.size
  return (bytecode, size)
}

public func getPathBytecode(from file: URL) throws -> [UInt8] {
  let img = try generateImagesAndPaths(from: [file])[0]
  return generatePathBytecode(route: img.pathRoutines[0])
}

public func getImagesMergedBytecodeAndPositions(
  from files: [URL]
) throws -> ([UInt8], [(Int, Int)], Int, [CGSize]) {
  let images = try generateImagesAndPaths(from: files).map(\.image)

  var imagePossitions: [(Int, Int)] = []
  var mergedBytecodes: [UInt8] = []
  var dimensions: [CGSize] = []

  for image in images {
    let bytecode = generateRouteBytecode(route: image.route)

    imagePossitions.append((
      mergedBytecodes.count,
      mergedBytecodes.count + bytecode.count - 1
    ))
    mergedBytecodes += bytecode
    dimensions.append(image.route.boundingRect.size)
  }

  return try (
    compressBytecode(mergedBytecodes),
    imagePossitions,
    mergedBytecodes.count,
    dimensions
  )
}
