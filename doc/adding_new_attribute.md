# Adding Support for a New SVG Attribute

This document outlines the steps to add support for a new SVG attribute in the cggen project, using the implementation of `stroke-miterlimit` as an example.

## Overview

When adding a new SVG attribute, you need to implement support across several components of the codebase:
1. SVG parsing
2. Data structures
3. Bytecode generation
4. Bytecode execution
5. Testing

## Implementation Steps

### 1. SVG Parsing

Add the attribute to the SVG parser:

1. Add the attribute name to the `Attribute` enum in `SVGParsing.swift`:
```swift
case strokeMiterlimit = "stroke-miterlimit"
```

2. Add a parser for the attribute value in `SVGAttributeParsers.swift`:
```swift
static let miterLimit = number
```

3. Add the attribute to the presentation attributes parser in `SVGParsing.swift`:
```swift
num(.strokeMiterlimit)
```

### 2. Data Structures

Add the attribute to the relevant data structures:

1. Add the property to `SVG.PresentationAttributes` in `SVG.swift`:
```swift
public var strokeMiterlimit: Float?
```

### 3. Bytecode Generation

Add support for the attribute in the bytecode generation:

1. Add a new case to `DrawStep` in `Routines.swift`:
```swift
case miterLimit(CGFloat)
```

2. Add a new case to `DrawCommand` in `Command.swift`:
```swift
case miterLimit
public typealias MiterLimitArgs = CGFloat
```

3. Add the case to the bytecode generation in `BytecodeGeneration.swift`:
```swift
case let .miterLimit(limit):
  encode(.miterLimit, DrawCommand.MiterLimitArgs.self, limit, >>)
```

### 4. Bytecode Execution

Add support for executing the new bytecode command:

1. Add the case to the bytecode runner in `BytecodeRunner.swift`:
```swift
case .miterLimit:
  try exec.miterLimit(read())
```

2. Implement the execution in the runner:
```swift
mutating func miterLimit(_ args: DrawCommand.MiterLimitArgs) {
  cg.setMiterLimit(args)
}
```

### 5. Testing

Create tests to verify the attribute works correctly:

1. Create an SVG test file (e.g., `miter_limit.svg`) that uses the attribute:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg width="50px" height="50px" viewBox="0 0 50 50" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <defs>
        <path id="p" d="m2 15 l2 -10 l3 10 l4 -10 l5 10 l6 -10"/>
    </defs>
    <g stroke="indianred" stroke-linejoin="miter" stroke-width="3" fill="none">
        <use xlink:href="#p" stroke-miterlimit="2.3"/>
        <use xlink:href="#p" x="25" stroke-miterlimit="3"/>
        <use xlink:href="#p" y="25" stroke-miterlimit="4"/>
        <use xlink:href="#p" x="25" y="25" stroke-miterlimit="5"/>
    </g>
</svg>
```

2. Add a test case in `SVGTests.swift`:
```swift
func testMiterLimit() {
    test(svg: "miter_limit")
}
```

The test uses the project's standard test infrastructure which:
- Renders the SVG using WebKit as a reference
- Renders the SVG using our implementation
- Compares the results with a configurable tolerance
- Generates visual diffs if the test fails

## Notes

- The implementation should follow the existing patterns in the codebase
- All changes should be properly tested
- The attribute should be documented in the code where appropriate
- Consider adding the attribute to the PDF support if relevant 