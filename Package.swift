// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "cggen",
  dependencies: [
    .package(url: "https://github.com/dmulholland/ArgParse.git", .exact("0.4.0")),
  ],
  targets: [
    .target(
      name: "cggen",
      dependencies: [ "ArgParse" ]),
  ]
)
