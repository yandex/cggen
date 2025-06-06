# cggen

Swift Package Manager plugin for generating optimized Swift drawing code from SVG and PDF files.

Instead of bundling vector assets as resources, cggen compiles them into bytecode and generates Swift functions that execute drawing operations using Core Graphics, resulting in smaller app bundles and better performance.

## Features

- **Swift Package Manager Plugin**: Automatic code generation during build
- **SVG and PDF Support**: Convert vector graphics from both formats  
- **Bytecode Compilation**: Generates compressed bytecode for efficient rendering
- **Swift-Friendly API**: Optional descriptor structs for better Swift integration
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

**Important:** Your target must depend on `cggen-runtime-support` library to provide the bytecode execution runtime.

## Usage

### Basic Setup

1. Place your `.svg` or `.pdf` files in your target's source directory
2. The plugin automatically finds and processes these files during build  
3. Generated Swift code provides drawing functions and descriptors

### Generated API

For an SVG file named `icon.svg`, cggen generates:

```swift
// Drawing function 
public func yourtargetDrawIconImage(in context: CGContext)

// Descriptor struct (swift-friendly mode)
public struct yourtargetIconDescriptor {
  public static let size: CGSize
  public static let draw: (CGContext) -> Void
}
```

**Note:** Function names use lowercase target prefix + camelCase filename. Target names with hyphens create invalid Swift identifiers.

### Example Usage

```swift
import CoreGraphics

// Create a graphics context
let context = CGContext(
  data: nil,
  width: 100, height: 100,
  bitsPerComponent: 8, bytesPerRow: 0,
  space: CGColorSpaceCreateDeviceRGB(),
  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Draw using generated function
yourtargetDrawIconImage(in: context)

// Or use descriptor (swift-friendly mode)
print("Icon size: \(yourtargetIconDescriptor.size)")
yourtargetIconDescriptor.draw(context)
```

### UIImage Helper

Add this extension to easily create UIImage instances:

```swift
extension UIImage {
  static func makeImage(size: CGSize, function: (CGContext) -> Void) -> UIImage {
    let scale = UIScreen.main.scale
    let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
      data: nil,
      width: Int(scaledSize.width),
      height: Int(scaledSize.height), 
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    
    context.scaleBy(x: scale, y: scale)
    function(context)
    
    let cgImage = context.makeImage()!
    return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
  }
}

// Usage
let image = UIImage.makeImage(size: yourtargetIconDescriptor.size) { context in
  yourtargetDrawIconImage(in: context)
}
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
Generates functions plus descriptor structs:
```swift
public struct targetImageNameDescriptor {
  public static let size: CGSize
  public static let draw: (CGContext) -> Void
}
```

## Architecture

The project uses a sophisticated bytecode compilation approach:

- **Input Parsing**: SVG and PDF parsers using swift-parsing library
- **Intermediate Representation**: DrawRoute and PathRoutine for graphics operations
- **Bytecode Generation**: Compiles drawing operations into compressed bytecode arrays
- **Runtime Execution**: CGGenRuntimeSupport library provides `runMergedBytecode_swift()` and `runPathBytecode_swift()` functions
- **Plugin System**: Swift Package Manager build tool plugin for automation

