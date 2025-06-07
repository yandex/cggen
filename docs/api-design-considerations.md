# API Design Considerations for cggen SwiftUI/UIKit Integration

This document outlines API approaches evaluated for making cggen-generated images seamlessly usable in SwiftUI and UIKit applications.

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
  static let heart = Drawing(size: CGSize(width: 24, height: 24), draw: drawHeart)
  static let star = Drawing(size: CGSize(width: 32, height: 32), draw: drawStar)
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
  static let circle = Drawing(size: CGSize(width: 50, height: 50), draw: pluginDemoDrawCircleImage)
  static let square = Drawing(size: CGSize(width: 40, height: 40), draw: pluginDemoDrawSquareImage)
}

fileprivate func pluginDemoDrawCircleImage(in context: CGContext) { /* drawing code */ }
fileprivate func pluginDemoDrawSquareImage(in context: CGContext) { /* drawing code */ }

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
