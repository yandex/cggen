// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "cggen",
  products: [
    .executable(name: "cggen", targets: ["cggen"]),
    .executable(name: "png-fuzzy-compare", targets: ["png-fuzzy-compare"]),
  ],
  targets: [
    .target(
      name: "png-fuzzy-compare",
      dependencies: ["ArgParse", "Base"]),
    .target(
      name: "cggen",
      dependencies: ["ArgParse", "Base"]),
    .target(
      name: "ArgParse"),
    .target(
      name: "Base"),
  ]
)
