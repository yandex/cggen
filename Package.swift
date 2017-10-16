// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "cggen",
  targets: [
    .target(
      name: "cggen",
      dependencies: [ "ArgParse" ]),
    .target(
      name: "ArgParse")
  ]
)
