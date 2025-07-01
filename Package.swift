// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
  name: "cggen",
  platforms: [
    .macOS(.v14), .iOS(.v13),
  ],
  products: [
    .executable(name: "cggen", targets: ["cggen"]),
    .library(name: "CGGenRuntime", targets: ["CGGenRuntime"]),
    .library(name: "CGGenRTSupport", targets: ["CGGenRTSupport"]),
    .plugin(name: "CGGenPlugin", targets: ["CGGenPlugin"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      .upToNextMajor(from: "1.5.1")
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-parsing",
      .upToNextMajor(from: "0.14.1")
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-snapshot-testing",
      .upToNextMajor(from: "1.17.6")
    ),
  ],
  targets: [
    // MARK: - Public targets (products)

    // CLI tool: converts SVG/PDF to Swift/ObjC code with bytecode
    .executableTarget(
      name: "cggen",
      dependencies: [
        "CGGenCLI",
        "Base",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),

    // Runtime SVG rendering: parse and render without code generation
    .target(
      name: "CGGenRuntime",
      dependencies: ["Base", "CGGenRTSupport", "CGGenIR"]
    ),

    // Runtime support: bytecode executor and helpers for image creation
    .target(
      name: "CGGenRTSupport",
      dependencies: ["BCCommon"],
      exclude: ["README.md"]
    ),

    // Build tool plugin: auto-generates code from SVG/PDF assets
    .plugin(
      name: "CGGenPlugin",
      capability: .buildTool(),
      dependencies: ["cggen"]
    ),

    // MARK: - Internal targets

    // Code generation logic: SVG/PDF to Swift/ObjC converters
    .target(
      name: "CGGenCLI",
      dependencies: [
        "Base", "SVGParse", "PDFParse", "BCCommon", "CGGenIR", "CGGenRTSupport",
      ]
    ),

    // Intermediate representation: DrawRoute and bytecode generation
    .target(
      name: "CGGenIR",
      dependencies: ["Base", "BCCommon", "SVGParse"]
    ),

    // Common utilities: parsers, math, colors, XML
    .target(
      name: "Base",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),

    // SVG parser: transforms SVG XML to typed structures
    .target(
      name: "SVGParse",
      dependencies: [
        "Base",
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),

    // PDF parser: reads PDF content streams and resources
    .target(
      name: "PDFParse",
      dependencies: ["Base"]
    ),

    // Bytecode definitions and compression
    .target(
      name: "BCCommon"
    ),

    // MARK: - Test targets

    .testTarget(
      name: "CGGenTests",
      dependencies: ["CGGenRuntime"]
    ),
    .testTarget(
      name: "UnitTests",
      dependencies: ["Base", "SVGParse", "CGGenCLI"],
      resources: [
        .copy("UnitTests.xctestplan"),
      ]
    ),
    .testTarget(
      name: "RegressionTests",
      dependencies: [
        "CGGenCLI", "CGGenRTSupport", "CGGenIR", "CGGenRuntime",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ],
      exclude: [
        "__Snapshots__",
        "RegressionSuite.xctestplan",
        "tests.sketch",
      ],
      resources: [
        .copy("pdf_samples"),
        .copy("svg_samples"),
        .copy("various_filenames"),
        .copy("Resources"),
      ]
    ),

    // MARK: - Example/Demo targets

    .executableTarget(
      name: "plugin-demo",
      dependencies: ["CGGenRTSupport"],
      plugins: ["CGGenPlugin"]
    ),
  ]
)
