// swift-tools-version:5.0
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
  ],
  targets: [
    .target(
      name: "cggen",
      dependencies: ["ArgParse", "libcggen", "Base"]
    ),
    .target(
      name: "libcggen",
      dependencies: ["Base", "PDFParse"]
    ),
    .target(
      name: "png-fuzzy-compare",
      dependencies: ["ArgParse", "Base"]
    ),
    .target(
      name: "pdf-to-png",
      dependencies: ["ArgParse", "Base"]
    ),
    .target(
      name: "ArgParse"
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
    )
  ]
)
