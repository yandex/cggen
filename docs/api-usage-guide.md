# cggen API Usage Guide

This guide provides comprehensive examples and usage patterns for the cggen Drawing API.

## Related Documentation
- [Architecture Overview](architecture.md) - Understanding cggen's structure
- [API Design Considerations](api-design-considerations.md) - Why the API works this way
- [Path Generation](path-generation.md) - Extracting paths for custom rendering

## Basic Usage

### SwiftUI Views
```swift
// Direct usage as views
Drawing.circle
Drawing.square
Drawing.star
```

### UIKit/AppKit Images

#### Preferred KeyPath Syntax (Swift 6.1+)
```swift
// UIKit
let circleImage = UIImage.draw(\.circle)
let starImage = UIImage.draw(\.star, scale: 2.0)

// AppKit
let circleImage = NSImage.draw(\.circle)
let starImage = NSImage.draw(\.star, scale: 2.0)
```

#### Direct Initializers
```swift
// UIKit
let circleImage = UIImage(drawing: .circle)
let starImage = UIImage(drawing: .star, scale: 2.0)

// AppKit
let circleImage = NSImage(drawing: .circle)
let starImage = NSImage(drawing: .star, scale: 2.0)
```

## Content Mode Support

The API includes comprehensive content mode support for generating images at specific sizes with different scaling behaviors.

### Available Content Modes

```swift
public enum DrawingContentMode {
  case scaleToFill    // Stretches image to fill target size
  case aspectFit      // Scales to fit within target, maintaining aspect ratio
  case aspectFill     // Scales to fill target, maintaining aspect ratio
  case center         // Centers at original size
  case top, bottom, left, right  // Edge alignments
  case topLeft, topRight, bottomLeft, bottomRight  // Corner alignments
}
```

### Creating Images with Content Modes

```swift
// Create thumbnail with aspect fit
let thumbnail = UIImage(
  drawing: .logo,
  size: CGSize(width: 100, height: 100),
  contentMode: .aspectFit
)

// Create banner with aspect fill
let banner = UIImage.draw(
  \.banner,
  size: CGSize(width: 320, height: 80),
  contentMode: .aspectFill
)

// Create icon maintaining aspect ratio
let icon = NSImage(
  drawing: .appIcon,
  size: CGSize(width: 64, height: 64),
  contentMode: .aspectFit
)
```

### Use Cases

#### Creating App Icons
```swift
let iconSizes = [16, 32, 64, 128, 256, 512, 1024]
let icons = iconSizes.map { size in
  UIImage(
    drawing: .appIcon,
    size: CGSize(width: size, height: size),
    contentMode: .aspectFit
  )
}
```

#### Generating Thumbnails
```swift
func createThumbnail(for drawing: Drawing, maxSize: CGFloat) -> UIImage {
  UIImage(
    drawing: drawing,
    size: CGSize(width: maxSize, height: maxSize),
    contentMode: .aspectFit
  )
}
```

#### Fitting to UI Components
```swift
// For a button with fixed size
let buttonIcon = UIImage(
  drawing: .menuIcon,
  size: button.bounds.size,
  contentMode: .center
)

// For a banner view
let bannerImage = UIImage(
  drawing: .headerGraphic,
  size: bannerView.bounds.size,
  contentMode: .aspectFill
)
```

## Core Graphics Direct Drawing

```swift
// Draw directly to a context
if let context = UIGraphicsGetCurrentContext() {
  Drawing.circle.draw(context)
  
  // Draw at specific position
  context.draw(Drawing.star, at: CGPoint(x: 50, y: 50))
}
```

## Platform Compatibility

- **SwiftUI**: All platforms supporting SwiftUI
- **UIKit**: iOS, tvOS, Mac Catalyst
- **AppKit**: macOS
- **Core Graphics**: All Apple platforms

## Performance Considerations

- Images are rendered on-demand
- Use appropriate scale factors for target displays
- Content mode calculations are performed during image creation
- Generated code uses optimized bytecode for efficient drawing
