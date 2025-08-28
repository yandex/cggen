# Path Generation Documentation

This document explains cggen's path generation feature, which allows you to extract and reuse path definitions from SVG files as standalone Core Graphics path functions.

## Related Documentation
- [Architecture Overview](architecture.md) - How path generation fits in cggen
- [API Usage Guide](api-usage-guide.md) - Using generated paths in your app
- [API Design Considerations](api-design-considerations.md) - Design decisions for path APIs
- [Adding New Attributes](adding-new-attribute.md) - Extending path support

## Overview

The path generation feature enables you to:
- Extract paths from SVG files as reusable components
- Generate compact bytecode representations of paths
- Create Swift functions that recreate paths programmatically
- Reuse complex paths across your application with different styles

## Architecture

The path generation feature involves several components working together:

```
SVG File → Parser → PathRoutine → BytecodeGenerator → Output
                         ↓
                   PathCommand
                         ↓
                   Runtime Execution
```

## How It Works

### Marking Paths for Extraction

To extract a path from an SVG file, prefix its ID with `cggen.`:

```xml
<svg viewBox="0 0 100 100">
  <defs>
    <!-- This path will be extracted -->
    <path id="cggen.starShape" d="M50,10 L60,40 L90,40 L65,60 L75,90 L50,70 L25,90 L35,60 L10,40 L40,40 Z"/>
    
    <!-- This path will NOT be extracted (no cggen. prefix) -->
    <path id="regularPath" d="M10,10 L90,90"/>
  </defs>
  
  <!-- You can still use the path in your SVG -->
  <use href="#cggen.starShape" fill="gold"/>
</svg>
```

### Path Extraction Process

The path extraction process starts in `SVGToDrawRouteConverter.swift`:

```swift
private func createPathRoutine(from svgNode: SVGNode, parentOpacity: Double) {
    // Check if ID starts with "cggen."
    let pathIdPrefix = "cggen."
    guard let id = svgNode.id, id.hasPrefix(pathIdPrefix) else { return }
    
    // Extract path name
    let pathName = String(id.dropFirst(pathIdPrefix.count))
    
    // Convert SVG path to segments
    let segments = segments(from: svgPath)
    
    // Create PathRoutine
    let pathRoutine = PathRoutine(
        name: pathName,
        rect: .zero,
        segments: segments
    )
}
```

### Data Structures

`PathRoutine` represents an extracted path:

```swift
struct PathRoutine {
    let name: String              // Path identifier (without cggen. prefix)
    let rect: CGRect             // Bounding box (currently always .zero)
    let segments: [PathSegment]  // Path commands
}
```

Path segments represent Core Graphics drawing commands:

```swift
enum PathSegment {
    case moveTo(CGPoint)
    case lineTo(CGPoint)
    case curveTo(cp1: CGPoint, cp2: CGPoint, end: CGPoint)
    case closePath
    case lines([CGPoint])
    case appendRectangle(CGRect)
    case appendRoundedRect(rect: CGRect, cornerRadius: CGSize)
    case addEllipse(CGRect)
    case addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool)
}
```

## Generated Output

### Swift Output (Unified Bytecode)

When you process an SVG file containing extractable paths, cggen now generates paths that share the same compressed bytecode array as images:

```swift
extension Drawing {
  static let star = Drawing(
    width: 60.0,
    height: 60.0,
    bytecodeArray: mergedBytecodes,
    decompressedSize: 275,
    startIndex: 140,
    endIndex: 274
  )
}

// MARK: - Paths

extension Drawing.Path {
  static let starShape = Drawing.Path(
    bytecodeArray: mergedBytecodes,
    decompressedSize: 275,
    startIndex: 275,
    endIndex: 340
  )
  static let customIcon = Drawing.Path(
    bytecodeArray: mergedBytecodes,
    decompressedSize: 275,
    startIndex: 341,
    endIndex: 400
  )
}

private let mergedBytecodes: [UInt8] = [
  // Compressed bytecode containing both images and paths
  0x62, 0x76, 0x78, 0x6E, 0x13, 0x01, 0x00, 0x00, ...
]
```

Paths are stored in the same compressed bytecode array as images, with start/end indices specifying their location.

### Objective-C Output

For Objective-C, paths are integrated into the main drawing bytecode with dedicated path creation commands:

```swift
// In drawing bytecode generation
case .pathRoutine(let name, let segments):
    bytecode.append(DrawCommand.createPath.rawValue)
    bytecode.append(contentsOf: name.utf8Count.bytes)
    bytecode.append(contentsOf: name.utf8)
    bytecode.append(contentsOf: generatePathBytecode(from: segments))
```

## Bytecode Format

### Path Commands

Path commands are defined in `BytecodeGeneration.swift`:

```swift
enum PathCommand: UInt8 {
    case moveTo = 0x01
    case lineTo = 0x02
    case curveTo = 0x03
    case closePath = 0x04
    case lines = 0x05
    case appendRectangle = 0x06
    case appendRoundedRect = 0x07
    case addEllipse = 0x08
    case addArc = 0x09
}
```

Each command is followed by its parameters encoded as 32-bit floats.

### Bytecode Generation

The `BCCGGenerator` converts path segments to bytecode:

```swift
func generatePathBytecode(from segments: [PathSegment]) -> [UInt8] {
    var bytecode: [UInt8] = []
    
    for segment in segments {
        switch segment {
        case .moveTo(let point):
            bytecode.append(PathCommand.moveTo.rawValue)
            bytecode.append(contentsOf: point.x.bytes)
            bytecode.append(contentsOf: point.y.bytes)
            
        case .lineTo(let point):
            bytecode.append(PathCommand.lineTo.rawValue)
            bytecode.append(contentsOf: point.x.bytes)
            bytecode.append(contentsOf: point.y.bytes)
            
        case .curveTo(let cp1, let cp2, let end):
            bytecode.append(PathCommand.curveTo.rawValue)
            bytecode.append(contentsOf: cp1.x.bytes)
            bytecode.append(contentsOf: cp1.y.bytes)
            bytecode.append(contentsOf: cp2.x.bytes)
            bytecode.append(contentsOf: cp2.y.bytes)
            bytecode.append(contentsOf: end.x.bytes)
            bytecode.append(contentsOf: end.y.bytes)
            
        // ... other cases
        }
    }
    
    return bytecode
}
```


## Runtime Execution

The runtime interpreter in `BytecodeRunner.swift`:

```swift
class PathBytecodeRunner {
    func run(bytecode: Data, in path: CGMutablePath) {
        var offset = 0
        
        while offset < bytecode.count {
            let command = PathCommand(rawValue: bytecode[offset])!
            offset += 1
            
            switch command {
            case .moveTo:
                let x = readFloat(at: &offset)
                let y = readFloat(at: &offset)
                path.move(to: CGPoint(x: x, y: y))
                
            case .lineTo:
                let x = readFloat(at: &offset)
                let y = readFloat(at: &offset)
                path.addLine(to: CGPoint(x: x, y: y))
                
            case .curveTo:
                let cp1x = readFloat(at: &offset)
                let cp1y = readFloat(at: &offset)
                let cp2x = readFloat(at: &offset)
                let cp2y = readFloat(at: &offset)
                let x = readFloat(at: &offset)
                let y = readFloat(at: &offset)
                path.addCurve(
                    to: CGPoint(x: x, y: y),
                    control1: CGPoint(x: cp1x, y: cp1y),
                    control2: CGPoint(x: cp2x, y: cp2y)
                )
                
            // ... other cases
            }
        }
    }
}
```

To use generated paths with the new unified bytecode system:

```swift
import CGGenRuntimeSupport

// Create a path and apply the Drawing.Path
let path = CGMutablePath()
Drawing.Path.starShape.apply(to: path)

// Or use it directly in drawing
context.draw { ctx in
    Drawing.Path.starShape.apply(to: ctx.path)
    ctx.fillPath()
}
```

The runtime provides the `Drawing.Path` struct with an `apply(to:)` method that decompresses and interprets the bytecode to construct the Core Graphics path.

## SVG Path Parsing

The SVG path parser handles all standard path commands:

```swift
func parsePathData(_ d: String) -> [PathSegment] {
    var segments: [PathSegment] = []
    var currentPoint = CGPoint.zero
    
    // Parse commands: M, L, C, Z, etc.
    // Handle both absolute and relative coordinates
    // Track current point for relative commands
    
    return segments
}
```

### Supported SVG Path Commands

- `M/m`: moveTo (absolute/relative)
- `L/l`: lineTo (absolute/relative)
- `C/c`: curveTo (cubic Bezier, absolute/relative)
- `S/s`: smooth curveTo (absolute/relative)
- `Q/q`: quadratic Bezier (converted to cubic)
- `T/t`: smooth quadratic Bezier
- `H/h`: horizontal lineTo
- `V/v`: vertical lineTo
- `Z/z`: closePath
- `A/a`: arc (converted to bezier curves)

## Usage Examples

### Basic Path Usage

```swift
// Create a path using the Drawing.Path API
let path = CGMutablePath()
Drawing.Path.starShape.apply(to: path)

// Use the path for drawing
context.addPath(path)
context.setFillColor(UIColor.blue.cgColor)
context.fillPath()
```

### Reusing Paths with Different Styles

```swift
func drawStars(in context: CGContext) {
    let starPath = CGMutablePath()
    Drawing.Path.starShape.apply(to: starPath)
    
    // Draw filled star
    context.saveGState()
    context.translateBy(x: 50, y: 50)
    context.addPath(starPath)
    context.setFillColor(UIColor.yellow.cgColor)
    context.fillPath()
    context.restoreGState()
    
    // Draw stroked star
    context.saveGState()
    context.translateBy(x: 150, y: 50)
    context.addPath(starPath)
    context.setStrokeColor(UIColor.red.cgColor)
    context.setLineWidth(2)
    context.strokePath()
    context.restoreGState()
}
```

### Creating Path Libraries

You can create SVG files specifically for path extraction:

```xml
<!-- icons.svg -->
<svg>
  <defs>
    <path id="cggen.home" d="M10,20 L10,11 L4,6 L-6,6 L0,0 L6,6 L4,6 L10,11 L10,20 L6,20 L6,14 L2,14 L2,20 Z"/>
    <path id="cggen.settings" d="M12,8 A4,4 0 1,1 4,8 A4,4 0 1,1 12,8 M10,0 L10,2 M10,14 L10,16..."/>
    <path id="cggen.user" d="M8,4 A4,4 0 1,1 0,4 A4,4 0 1,1 8,4 M0,10 Q0,14 4,14 Q8,14 8,10"/>
  </defs>
</svg>
```

This generates individual path functions for each icon that you can use throughout your app.

### Path Transformation

Since paths are created programmatically, you can apply transformations:

```swift
let path = CGMutablePath()
Drawing.Path.starShape.apply(to: path)

// Apply transformation
var transform = CGAffineTransform.identity
transform = transform.scaledBy(x: 2, y: 2)
transform = transform.rotated(by: .pi / 4)

if let transformedPath = path.copy(using: &transform) {
    context.addPath(transformedPath)
    context.fillPath()
}
```

### Example: Creating Hit Test Areas

Extracted paths can be used for hit testing:

```swift
class CustomButton: UIView {
    let shapePath = CGMutablePath()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Drawing.Path.starShape.apply(to: shapePath)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return shapePath.contains(point)
    }
}
```

## Best Practices

1. **Naming Convention**: Use descriptive names after `cggen.` prefix:
   - Good: `cggen.iconHome`, `cggen.shapeRoundedStar`
   - Bad: `cggen.path1`, `cggen.p`

2. **Path Organization**: Group related paths in the same SVG file:
   ```xml
   <!-- navigation-icons.svg -->
   <defs>
     <path id="cggen.navBack" d="..."/>
     <path id="cggen.navForward" d="..."/>
     <path id="cggen.navHome" d="..."/>
   </defs>
   ```

3. **Coordinate System**: Design paths in a consistent coordinate system (e.g., 0-100 or 0-24) for easy scaling.

4. **Testing Paths**: Use the `<use>` element in your SVG to visualize paths:
   ```xml
   <use href="#cggen.myPath" fill="black" opacity="0.5"/>
   ```

## Testing

### Path Extraction Tests

The test suite includes comprehensive path validation:

```swift
@Test func pathExtraction() {
    let svg = """
    <svg>
        <path id="cggen.test" d="M0,0 L10,10 C20,20 30,30 40,40 Z"/>
    </svg>
    """
    
    let result = SVGToDrawRouteConverter.convert(svgString: svg)
    
    #expect(result.paths.count == 1)
    #expect(result.paths[0].name == "test")
    #expect(result.paths[0].segments.count == 4) // moveTo, lineTo, curveTo, closePath
}
```

### Path Comparison

Tests use tolerance-based comparison for floating-point values:

```swift
func pathsEqual(_ path1: [PathSegment], _ path2: [PathSegment], tolerance: CGFloat = 0.001) -> Bool {
    guard path1.count == path2.count else { return false }
    
    for (seg1, seg2) in zip(path1, path2) {
        if !segmentsEqual(seg1, seg2, tolerance: tolerance) {
            return false
        }
    }
    
    return true
}
```

## Debugging

### Inspecting Generated Bytecode

To debug path generation:
1. Set breakpoints in `generatePathBytecode()`
2. Print bytecode as hex: `bytecode.map { String(format: "%02X", $0) }.joined(separator: " ")`
3. Verify command sequences match expected path operations

### Validating Path Output

Use Core Graphics to render and verify paths:
```swift
let path = CGMutablePath()
testPath(in: path)

// Render to image for visual inspection
UIGraphicsBeginImageContext(CGSize(width: 100, height: 100))
let context = UIGraphicsGetCurrentContext()!
context.addPath(path)
context.strokePath()
let image = UIGraphicsGetImageFromCurrentImageContext()
UIGraphicsEndImageContext()
```

## Integration Points

### With Drawing System

Extracted paths can be integrated into the main drawing:
```swift
// In draw route
case .usePath(let pathName):
    if let pathFunc = generatedPaths[pathName] {
        let path = CGMutablePath()
        pathFunc(path)
        context.addPath(path)
    }
```

### With Animation Systems

Since paths are generated programmatically, they can be animated:
```swift
// Morphing between paths
func interpolatePaths(from: CGPath, to: CGPath, progress: CGFloat) -> CGPath {
    // Path interpolation logic
}
```

## Performance Considerations

The bytecode format is designed for efficiency:
- Commands are single bytes
- Coordinates are 32-bit floats (4 bytes each)
- No string parsing at runtime
- Sequential memory access pattern

## Limitations

1. Only `<path>` elements can be extracted (not `<rect>`, `<circle>`, etc.)
2. Transformations on the path element are not applied during extraction
3. SVG path effects are not supported
4. Path markers are ignored
