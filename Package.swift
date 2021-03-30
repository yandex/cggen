// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "cggen",
  platforms: [
    .macOS(.v10_14), .iOS(.v12),
  ],
  products: [
    .executable(name: "cggen", targets: ["cggen"]),
    .executable(name: "png-fuzzy-compare", targets: ["png-fuzzy-compare"]),
    .executable(name: "pdf-to-png", targets: ["pdf-to-png"]),
    .library(name: "cggen-bc-runner", targets: ["BCRunner"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      .upToNextMinor(from: "0.4.0")
    ),
  ],
  targets: [
    .target(
      name: "BCRunner"
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
      dependencies: ["Base", "PDFParse"]
    ),
    .target(
      name: "png-fuzzy-compare",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "Base",
      ]
    ),
    .target(
      name: "pdf-to-png",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "Base",
      ]
    ),
    .target(
      name: "Base"
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
      dependencies: ["libcggen"]
    ),
  ]
)
