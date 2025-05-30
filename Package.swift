// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
  name: "cggen",
  platforms: [
    .macOS(.v10_15), .iOS(.v12),
  ],
  products: [
    .executable(name: "cggen", targets: ["cggen"]),
    .library(name: "cggen-bc-runner", targets: ["BCRunner"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      .upToNextMinor(from: "0.4.0")
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-parsing",
      .upToNextMajor(from: "0.14.1")
    ),
  ],
  targets: [
    .target(
      name: "BCCommon"
    ),
    .target(
      name: "BCRunner",
      dependencies: ["BCCommon"]
    ),
    .target(
      name: "cggen",
      dependencies: [
        "libcggen",
        "Base",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .target(
      name: "libcggen",
      dependencies: ["Base", "PDFParse", "BCCommon"]
    ),
    .target(
      name: "Base",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
    .target(
      name: "PDFParse",
      dependencies: ["Base"]
    ),
    .testTarget(
      name: "UnitTests",
      dependencies: ["Base", "libcggen"]
    ),
    .testTarget(
      name: "RegressionTests",
      dependencies: ["libcggen", "BCRunner"]
    ),
  ]
)
