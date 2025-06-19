# Changelog

All notable changes to cggen will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-19

### Added
- Runtime SVG rendering support via `CGGenRuntime` module (#88)
- Swift Package Manager plugin for automatic code generation (#59)
- SwiftUI-friendly Drawing API with KeyPath syntax for Swift 6.1+ (#62)
- Equatable and Hashable conformance for Drawing struct (#71)
- Native quadratic Bezier curve support (#89)
- Xcode project integration support (Beta) (#77)
- SVG stroke-miterlimit attribute support (#69)
- Comprehensive demo applications (Demo app and plugin-demo)
- Path extraction API for animations and custom rendering
- Content mode support for flexible scaling options
- Cross-platform support (iOS, macOS, SwiftUI, UIKit, AppKit)

### Changed
- Refactored SVG parsers into separate focused modules (#81, #82)
- Migrated to swift-parsing library for better parser composition (#80)
- Renamed CGGenDemo to Demo for simplicity (#74)
- Renamed plugin to cggen-spm-plugin for clarity (#72)
- Optimized Drawing struct memory usage (#71)
- Applied Swift 6 formatting and project cleanup (#78)
- Improved code generation with better C bytecode formatting (#73)

### Fixed
- Sanitized target names for Swift identifiers (#76)
- Fixed whitespace parser crash in Swift internals (#58)
- Fixed demo app UI issues (#68)

### Security
- All generated code now uses compressed bytecode for smaller app bundles
- No runtime file access required - all assets compiled at build time

## [0.1.0] - Initial Release

### Added
- Basic SVG and PDF to Core Graphics code generation
- Command-line interface
- Support for common SVG elements and attributes
- Objective-C code generation option