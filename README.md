# cggen

Swift Package Manager plugin for generating optimized Swift drawing code from SVG and PDF files.

Instead of bundling vector assets as resources, cggen compiles them into bytecode and generates Swift functions that execute drawing operations using Core Graphics, resulting in smaller app bundles and better performance.

## Features

- **Swift Package Manager Plugin**: Automatic code generation during build
- **SVG and PDF Support**: Convert vector graphics from both formats  
- **Bytecode Compilation**: Generates compressed bytecode for efficient rendering
- **Swift-Friendly API**: Tuple descriptors for clean Swift integration  
- **Image Creation Utilities**: Built-in support for CGImage, UIImage, and SwiftUI.Image
- **Build-Time Generation**: No runtime dependencies beyond cggen-runtime-support library

## Installation

Add cggen as a dependency to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/yandex/cggen", from: "1.0.0")
]
```

Add the plugin to your target and include runtime dependency:

```swift
.target(
  name: "YourTarget", 
  dependencies: [
    .product(name: "cggen-runtime-support", package: "cggen")
  ],
  plugins: [
    .plugin(name: "plugin", package: "cggen")
  ]
)
```

**Important:** Your target must depend on `cggen-runtime-support` library to provide the bytecode execution runtime and image creation utilities.

## Usage

### Basic Setup

1. Place your `.svg` or `.pdf` files in your target's source directory
2. The plugin automatically finds and processes these files during build  
3. Generated Swift code provides drawing functions and descriptors

### Generated API

For an SVG file named `icon.svg`, cggen generates:

```swift
// Drawing function 
fileprivate func yourtargetDrawIconImage(in context: CGContext)

// Tuple descriptor (swift-friendly mode)
public let yourtargeticon = (
  size: CGSize(width: 24.0, height: 24.0),
  draw: yourtargetDrawIconImage
)
```

**Note:** Function names use lowercase target prefix + camelCase filename. Target names with hyphens create invalid Swift identifiers.

### Example Usage

```swift
import CoreGraphics
import cggen_runtime_support

// Create a graphics context
let context = CGContext(
  data: nil,
  width: 100, height: 100,
  bitsPerComponent: 8, bytesPerRow: 0,
  space: CGColorSpaceCreateDeviceRGB(),
  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Draw using generated function directly
yourtargeticon.draw(context)

// Or access descriptor properties
print("Icon size: \(yourtargeticon.size)")
```

### Image Creation

The runtime support library provides convenient image creation utilities:

```swift
import cggen_runtime_support

// Create a CGImage
if let cgImage = CGImage.draw(from: yourtargeticon) {
  // Use cgImage...
}

// Create a UIImage (iOS/tvOS/watchOS)
#if canImport(UIKit)
let uiImage = UIImage(yourtargeticon)
#endif

// Create a SwiftUI Image
#if canImport(SwiftUI)
let swiftUIImage = Image(yourtargeticon)
#endif
```

## CLI Usage

The underlying CLI tool can be used directly for custom workflows:

```bash
swift run cggen --swift-output Generated.swift --generation-style swift-friendly input.svg input.pdf
```

### CLI Options

- `--swift-output <path>`: Generate Swift code to specified file
- `--generation-style <style>`: Either "plain" or "swift-friendly" (default: "plain")
- `--objc-prefix <prefix>`: Add prefix to generated function names
- `--module-name <name>`: Module name for generated code
- `--objc-header <path>`: Generate Objective-C header file
- `--objc-impl <path>`: Generate Objective-C implementation file  
- `--verbose`: Enable debug output

## Generation Styles

### Plain Mode (default)
Generates only drawing functions:
```swift
public func targetDrawImageNameImage(in context: CGContext)
```

### Swift-Friendly Mode  
Generates functions plus tuple descriptors:
```swift
public let targetimagename = (
  size: CGSize(width: 24.0, height: 24.0),
  draw: targetDrawImageNameImage
)
```

## Architecture

The project uses a sophisticated bytecode compilation approach:

- **Input Parsing**: SVG and PDF parsers using swift-parsing library
- **Intermediate Representation**: DrawRoute and PathRoutine for graphics operations
- **Bytecode Generation**: Compiles drawing operations into compressed bytecode arrays
- **Runtime Execution**: cggen-runtime-support library provides `runMergedBytecode_swift()` and `runPathBytecode_swift()` functions
- **Plugin System**: Swift Package Manager build tool plugin for automation

