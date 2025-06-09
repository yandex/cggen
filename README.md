# cggen

Swift Package Manager plugin for generating optimized Swift drawing code from SVG and PDF files.

Instead of bundling vector assets as resources, cggen compiles them into compressed bytecode and generates Swift code that executes drawing operations using Core Graphics, resulting in smaller app bundles and better performance.

## Features

- **Swift Package Manager Plugin**: Automatic code generation during build
- **SVG and PDF Support**: Convert vector graphics from both formats  
- **Bytecode Compilation**: Generates compressed bytecode for efficient rendering
- **Memory-Optimized Drawing**: Equatable/Hashable Drawing struct with minimal memory footprint
- **SwiftUI Integration**: Direct usage of drawings as SwiftUI views
- **Cross-Platform Support**: Works with UIKit, AppKit, and SwiftUI
- **Content Mode Support**: Comprehensive scaling options for different use cases

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
    .plugin(name: "cggen-spm-plugin", package: "cggen")
  ]
)
```

**Important:** Your target must depend on `cggen-runtime-support` library to provide the bytecode execution runtime.

## Usage

### Basic Setup

1. Place your `.svg` or `.pdf` files in your target's source directory
2. The plugin automatically finds and processes these files during build  
3. Generated Swift code provides Drawing namespace with your graphics

### Generated API

For SVG files like `icon.svg`, `logo.svg`, cggen generates:

```swift
// Drawing namespace with static properties
extension Drawing {
  static let icon = Drawing(
    width: 24.0,
    height: 24.0,
    bytecodeArray: mergedBytecodes,
    decompressedSize: 1234,
    startIndex: 0,
    endIndex: 567
  )
  
  static let logo = Drawing(/* ... */)
}
```

The `Drawing` struct conforms to Equatable and Hashable protocols.

### SwiftUI Usage

Use drawings directly as views:

```swift
import SwiftUI
import CGGenRuntimeSupport

struct ContentView: View {
  var body: some View {
    VStack {
      Drawing.icon
        .foregroundColor(.blue)
        .frame(width: 44, height: 44)
      
      Drawing.logo
        .shadow(radius: 5)
    }
  }
}
```

### UIKit/AppKit Usage

Create platform images using various APIs:

```swift
import UIKit
import CGGenRuntimeSupport

// Using KeyPath API (Swift 6.1+)
let iconImage = UIImage.draw(\.icon)
let scaledIcon = UIImage.draw(\.icon, scale: 2.0)

// Using direct initializers
let logoImage = UIImage(drawing: .logo)
let thumbnail = UIImage(
  drawing: .logo,
  size: CGSize(width: 100, height: 100),
  contentMode: .aspectFit
)

// AppKit (macOS)
let nsIcon = NSImage.draw(\.icon)
let nsLogo = NSImage(drawing: .logo)
```

### Content Modes

Control how drawings scale to fit target sizes:

```swift
public enum DrawingContentMode {
  case scaleToFill    // Stretches to fill
  case aspectFit      // Fits within bounds
  case aspectFill     // Fills bounds, may crop
  case center         // Original size, centered
  case top, bottom, left, right
  case topLeft, topRight, bottomLeft, bottomRight
}

// Example: Create app icons at various sizes
let icon = UIImage(
  drawing: .appIcon,
  size: CGSize(width: 128, height: 128),
  contentMode: .aspectFit
)
```

### Core Graphics Direct Drawing

Draw directly to a graphics context:

```swift
if let context = UIGraphicsGetCurrentContext() {
  // Draw at origin
  Drawing.logo.draw(in: context)
  
  // Draw at specific position
  context.saveGState()
  context.translateBy(x: 100, y: 50)
  Drawing.icon.draw(in: context)
  context.restoreGState()
}
```

## Demo Applications

### CGGenDemo
A comprehensive demo app showcasing all cggen features:
- **Location**: `CGGenDemo/`
- **Platforms**: macOS and iOS
- **Features**: SwiftUI, AppKit, and UIKit examples with interactive playground
- **Build**: Open `CGGenDemo/CGGenDemo.xcodeproj` in Xcode

### Plugin Demo
Command-line demonstration of the plugin functionality:
- **Location**: `Sources/plugindemo/`
- **Features**: Shows all API patterns and platform-specific usage
- **Run**: `swift run plugindemo`

## CLI Usage

The underlying CLI tool can be used directly for custom workflows:

```bash
swift run cggen --swift-output Generated.swift input.svg input.pdf
```

### CLI Options

- `--swift-output <path>`: Generate Swift code to specified file
- `--generation-style <style>`: Either "plain" or "swift-friendly" (default: "plain")
- `--objc-prefix <prefix>`: Add prefix to generated function names
- `--module-name <name>`: Module name for generated code
- `--objc-header <path>`: Generate Objective-C header file
- `--objc-impl <path>`: Generate Objective-C implementation file  
- `--verbose`: Enable debug output

## Architecture

cggen uses a sophisticated compilation approach:

1. **Parsing**: SVG and PDF files are parsed into internal representations
2. **Intermediate Representation**: Graphics operations are converted to DrawRoute/PathRoutine structures
3. **Bytecode Generation**: Operations are compiled into compressed bytecode arrays (LZFSE compression)
4. **Code Generation**: Swift code is generated with the Drawing namespace
5. **Runtime Execution**: CGGenRuntimeSupport provides bytecode execution


## Documentation

- [API Usage Guide](docs/api-usage-guide.md) - Comprehensive examples and patterns
- [API Design Considerations](docs/api-design-considerations.md) - Design decisions and alternatives
- [Adding New Attributes](docs/adding_new_attribute.md) - Guide for contributing SVG attribute support

