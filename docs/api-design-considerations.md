# API Design Considerations for cggen SwiftUI/UIKit Integration

This document outlines API approaches evaluated for making cggen-generated images seamlessly usable in SwiftUI and UIKit applications.

## Related Documentation
- [API Usage Guide](api-usage-guide.md) - Practical examples of the chosen API
- [Architecture Overview](architecture.md) - How cggen implements these decisions
- [Path Generation](path-generation.md) - Extended API for path extraction

## Goal

Create a simple and ergonomic API that enables developers to integrate cggen-generated vector graphics similarly to system images, without manual support library imports.

## Design Constraints

1. **Cross-platform**: Naturally compatible with various UI frameworks.
2. **Type Safety**: Compile-time validation of image references.

## Approaches Evaluated

### 1. Direct Static Properties

```swift
// Generated
extension UIImage {
  static var circle: UIImage { UIImage(plugindemocircle) }
  static var square: UIImage { UIImage(plugindemosquare) }
}

extension Image {
  static var circle: Image { Image(plugindemocircle) }
  static var square: Image { Image(plugindemosquare) }
}

// User
Image.circle
UIImage.square
```

**Pros:**

* Simplest and intuitive.
* Effective type inference.

**Cons:**

* Large amounts of generated code.
* Poor extensibility for new image types.

### 2. Namespace with Dynamic Member Lookup

```swift
@dynamicMemberLookup
struct ImageProxy<Namespace, Transform: ImageTransform> {
  subscript(dynamicMember member: KeyPath<Namespace.Type, Transform.Descriptor>) -> Transform.PlatformImage {
    Transform.transform(namespace[keyPath: member])
  }
}

// Generated
enum AppImages {
  static let heart: Drawing = appheart
  static let star: Drawing = appstar
}

extension Image {
  static let app = ImageProxy<AppImages, SwiftUITransform>(AppImages.self)
}

// User
Image.app.heart
UIImage.app.star
```

**Pros:**

* Clean syntax with namespaced images.
* Avoids naming collisions.
* Highly extensible.

**Cons:**

* Verbose namespaces (e.g., `.module.image`).

### 3. KeyPath-based Factory Methods

```swift
// Runtime support (CGGenRuntimeSupport)
extension UIImage {
  static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>) -> UIImage {
    UIImage(Drawing.self[keyPath: keyPath])
  }
}

extension Image {
  static func draw(_ keyPath: KeyPath<Drawing.Type, Drawing>) -> Image {
    Image(Drawing.self[keyPath: keyPath])
  }
}

// Generated
extension Drawing {
  static let heart = Drawing(
    width: 24.0,
    height: 24.0,
    bytecodeArray: mergedBytecodes,
    decompressedSize: 1234,
    startIndex: 0,
    endIndex: 567
  )
  static let star = Drawing(
    width: 32.0,
    height: 32.0,
    bytecodeArray: mergedBytecodes,
    decompressedSize: 1234,
    startIndex: 568,
    endIndex: 1100
  )
}

// User
UIImage.draw(\.heart)
Image.draw(\.star)
```

**Pros:**

* SwiftUI-like syntax.
* No namespace pollution.

**Cons:**

* Requires static methods on every type.
* Potentially unfamiliar syntax for some developers.

### 4. Drawing Namespace Approach (SwiftUI Convenience)

```swift
// Generated
import CoreGraphics
import CGGenRuntimeSupport

typealias Drawing = CGGenRuntimeSupport.Drawing

extension Drawing {
  static let circle = Drawing(
    width: 50.0,
    height: 50.0,
    bytecodeArray: mergedBytecodes,
    decompressedSize: 275,
    startIndex: 0,
    endIndex: 65
  )
  static let square = Drawing(
    width: 40.0,
    height: 40.0,
    bytecodeArray: mergedBytecodes,
    decompressedSize: 275,
    startIndex: 66,
    endIndex: 139
  )
}

private let mergedBytecodes: [UInt8] = [
  // Compressed bytecode array
]

// User
struct ContentView: View {
  var body: some View {
    Drawing.circle
    Drawing.square
  }
}
```

**Pros:**

* Clean, clear namespace.
* Seamless SwiftUI integration.
* Avoids explicit user-facing imports.

## Final Decision

A hybrid approach combining **Drawing namespace (#4)** and **KeyPath-based methods (#3)**:

* **SwiftUI Views:** Direct usage as views (`Drawing.circle`).
* **UIKit/AppKit Images:**

  * Preferred: KeyPath-based (`UIImage.draw(\.circle)`).
  * Alternative: Direct initializer (`UIImage(drawing: .circle)`).
* **Core Graphics:** Direct drawing (`Drawing.circle.draw(context)`).

This approach provides a clean, consistent API across platforms, offering optimal ergonomics for all scenarios.
