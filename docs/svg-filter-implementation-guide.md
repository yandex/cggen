# SVG Filter Implementation Guide for cggen

## Overview

This document outlines the implementation strategy for adding comprehensive SVG filter support to cggen. The approach treats filters as binary-encoded DAG structures (like paths), referenced by a single DrawCommand, and executed at runtime by BytecodeRunner using Core Image.

## Current State

cggen currently supports:
- **Implemented**: Simple drop shadows via pattern matching (offset + blur + color matrix)
- **Parsed but ignored**: feBlend, feColorMatrix, feFlood, feGaussianBlur, feOffset
- **Throws error**: Any filter that doesn't match the shadow pattern (`tooComplexFilter`)

## Architecture Overview

### Filter DAG as Binary Structure

Filters will be encoded as separate binary structures (like paths), not as DrawCommand sequences:

```
[node_count: varint]
[Node entries in topological order]:
  - type_id: UInt8 (Offset=1, GaussianBlur=2, etc.)
  - payload: type-specific data
  - in_degree: varint
  - deltas: [varint] (backward references)
```

### Integration Points

1. **SVGToDrawRouteConverter**: Convert filter to DAG, encode, and emit `applyFilter` DrawStep
2. **BytecodeGeneration**: Encode filter DAG and add to bytecode
3. **BytecodeRunner**: Pre-load filters, execute DAG when encountering `applyFilter` command

## Implementation Milestones

### Phase 1: Foundation (Week 1-2)

#### Milestone 1.1: Basic Filter Infrastructure
**Goal**: Add minimal structure without breaking existing functionality

**Tasks**:
1. Add `FilterDAG` type to CGGenIR:
```swift
struct FilterDAG {
    let nodes: [FilterNode]
}

struct FilterNode {
    let type: FilterNodeType
    let inputs: [Int]  // Indices to previous nodes
    let params: Data   // Type-specific parameters
}

enum FilterNodeType: UInt8 {
    case sourceGraphic = 0
    case offset = 1
    // More to come later
}
```

2. Extend DrawStep:
```swift
case applyFilter(filterId: Int, bounds: CGRect)
```

3. Add to DrawCommand:
```swift
case applyFilter = 0x80  // New command
```

**Tests**: Ensure existing tests pass

#### Milestone 1.2: Hook into Existing Flow
**Goal**: Intercept filter processing before throwing `tooComplexFilter`

**Tasks**:
1. Modify SVGToDrawRouteConverter:
```swift
private func convertFilter(_ filter: SVGDocument.SVGFilter) throws -> [DrawStep] {
    // Keep existing shadow detection
    if let shadow = try? simpleShadow(filter) {
        return [.shadow(shadow)]
    }
    
    // New: Try filter DAG conversion (gated by flag)
    if ProcessInfo.processInfo.environment["CGGEN_FILTER_DAG"] == "1" {
        if let dag = try? convertToFilterDAG(filter) {
            let filterId = storeFilterDAG(dag)
            return [.applyFilter(filterId: filterId, bounds: calculateBounds(filter))]
        }
    }
    
    // Fall back to error
    throw Err.tooComplexFilter
}
```

2. Stub implementation that always fails for now

**Tests**: Verify shadow filters still work

### Phase 2: Simple Filter DAG (Week 2-3)

#### Milestone 2.1: Implement Offset-Only Filter
**Goal**: Simplest possible filter DAG with SourceGraphic → Offset

**Tasks**:
1. Implement DAG construction for offset:
```swift
func convertToFilterDAG(_ filter: SVGDocument.SVGFilter) throws -> FilterDAG? {
    // Only handle single offset for now
    guard filter.primitives.count == 1,
          case .offset(let offset) = filter.primitives[0] else {
        return nil
    }
    
    return FilterDAG(nodes: [
        FilterNode(type: .sourceGraphic, inputs: [], params: Data()),
        FilterNode(type: .offset, inputs: [0], params: encodeOffset(offset))
    ])
}
```

2. Implement binary encoding:
```swift
func encodeFilterDAG(_ dag: FilterDAG) -> Data {
    var data = Data()
    data.append(varint(dag.nodes.count))
    
    for (index, node) in dag.nodes.enumerated() {
        data.append(node.type.rawValue)
        data.append(node.params)
        data.append(varint(node.inputs.count))
        for input in node.inputs {
            data.append(varint(index - input))  // Delta encoding
        }
    }
    
    return data
}
```

**Tests**:
```xml
<!-- test_offset_only.svg -->
<svg viewBox="0 0 100 100">
  <filter id="offset">
    <feOffset dx="10" dy="10"/>
  </filter>
  <rect x="20" y="20" width="60" height="60" filter="url(#offset)"/>
</svg>
```

#### Milestone 2.2: BytecodeRunner Filter Execution
**Goal**: Execute the offset filter in BytecodeRunner

**Tasks**:
1. Add filter storage to BytecodeRunner:
```swift
class BytecodeRunner {
    var filters: [FilterDAG] = []
    
    func loadFilters(_ filterData: [Data]) {
        filters = filterData.map { decodeFilterDAG($0) }
    }
}
```

2. Implement `applyFilter` command:
```swift
case .applyFilter:
    let filterId = readVarint()
    let bounds = readRect()
    executeFilter(filters[filterId], bounds: bounds)
```

3. Basic filter execution (offset only):
```swift
func executeFilter(_ dag: FilterDAG, bounds: CGRect) {
    // Capture current drawing
    let sourceImage = captureContext(bounds)
    
    // Execute nodes
    var results: [CGImage] = [sourceImage]
    
    for node in dag.nodes.dropFirst() {  // Skip source
        switch node.type {
        case .offset:
            let (dx, dy) = decodeOffset(node.params)
            let input = results[node.inputs[0]]
            results.append(applyOffset(input, dx: dx, dy: dy))
        default:
            break
        }
    }
    
    // Draw final result
    drawImage(results.last!, in: bounds)
}
```

**Tests**: Verify offset filter works

### Phase 3: Filter Chaining (Week 3-4)

#### Milestone 3.1: Add Gaussian Blur
**Goal**: Support SourceGraphic → Blur

**Tasks**:
1. Add blur node type:
```swift
enum FilterNodeType: UInt8 {
    case sourceGraphic = 0
    case offset = 1
    case gaussianBlur = 2
}
```

2. Extend DAG converter:
```swift
case .gaussianBlur(let blur):
    return FilterNode(type: .gaussianBlur, 
                     inputs: [previousNodeIndex],
                     params: encodeFloat(blur.stdDeviation))
```

3. Implement blur in BytecodeRunner using Core Image

**Tests**: Single blur filter

#### Milestone 3.2: Support Filter Chains
**Goal**: Handle multiple primitives (e.g., Blur → Offset)

**Tasks**:
1. Implement topological sort for DAG nodes
2. Handle named results and references
3. Support multiple inputs (for blend operations later)

**Tests**:
```xml
<!-- test_blur_offset_chain.svg -->
<filter id="shadow">
  <feGaussianBlur in="SourceGraphic" stdDeviation="3" result="blur"/>
  <feOffset in="blur" dx="5" dy="5"/>
</filter>
```

### Phase 4: More Primitives (Week 4-5)

#### Milestone 4.1: Color Matrix
**Tasks**:
1. Add color matrix node type
2. Implement different matrix types (saturate, hueRotate, matrix)
3. Add Core Image integration

#### Milestone 4.2: Blend Operations
**Tasks**:
1. Add blend node type with two inputs
2. Support different blend modes
3. Handle SourceGraphic + processed result blending

### Phase 5: Production Ready (Week 5-6)

#### Milestone 5.1: Memory Management
**Tasks**:
1. Implement proper bitmap lifecycle
2. Add autorelease pools for Core Image
3. Cache CIContext instances

#### Milestone 5.2: Platform Compatibility
**Tasks**:
1. Abstract iOS/macOS differences
2. Add fallbacks for missing Core Image filters
3. Handle color space conversions

#### Milestone 5.3: Performance Optimization
**Tasks**:
1. Detect and optimize common patterns
2. Reuse bitmap contexts
3. Implement filter result caching

### Phase 6: Extended Support (Week 6-8)

#### Milestone 6.1: Additional Primitives
- feFlood
- feComposite
- feMorphology
- feColorMatrix variants

#### Milestone 6.2: Remove Feature Flag
**Tasks**:
1. Comprehensive testing
2. Performance benchmarking
3. Documentation updates
4. Migration guide

## Technical Considerations

### Filter Bounds Calculation
```swift
func calculateFilterBounds(_ element: Element, _ filter: Filter) -> CGRect {
    var bounds = element.bounds
    
    // Expand for blur
    if let maxBlur = filter.maxBlurRadius {
        bounds = bounds.insetBy(dx: -maxBlur * 3, dy: -maxBlur * 3)
    }
    
    // Apply filter region if specified
    if let region = filter.filterRegion {
        bounds = bounds.intersection(region)
    }
    
    return bounds
}
```

### Binary Size Optimization
- Use varints for all counts and indices
- Delta encoding for node references
- Type-specific compact parameter encoding
- Consider compression for large filter chains

### Error Handling
- Invalid filter references → skip filter
- Unsupported primitives → log warning, pass through
- Memory allocation failures → graceful degradation

## Testing Strategy

### Unit Tests
1. Filter DAG construction
2. Binary encoding/decoding
3. Individual primitive execution
4. Filter chain resolution

### Integration Tests
1. End-to-end SVG → rendered output
2. Complex filter chains
3. Edge cases (empty filters, circular references)

### Performance Tests
1. Filter encoding size
2. Execution time vs complexity
3. Memory usage patterns

## Migration Path

1. All changes behind `CGGEN_FILTER_DAG=1` flag
2. Existing shadow filters continue to work
3. Gradual primitive support
4. No API changes required

## Success Metrics

1. 80% of common filter patterns supported
2. Binary size increase < 10% for typical SVGs
3. Runtime performance within 2x of native implementation
4. Zero regressions in existing functionality

## Timeline

- **Phase 1**: Foundation (1-2 weeks)
- **Phase 2**: Simple DAG (1 week)
- **Phase 3**: Chaining (1 week)
- **Phase 4**: More Primitives (1 week)
- **Phase 5**: Production (1 week)
- **Phase 6**: Extended (2 weeks)
- **Total**: 6-8 weeks

## Conclusion

This approach treats filters as data rather than code, enabling compact representation while maintaining flexibility. The incremental milestones allow for continuous integration without breaking existing functionality.
