# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build
- Release build: `swift build --product cggen --configuration release`
- Debug build: `swift build`
- Verbose build: `swift build -v`

### Test
- All tests: `swift test`
- Parallel tests: `swift test --parallel`
- Specific test: `swift test --filter <test-name>`
- List tests: `swift test list`

### Lint and Type Checking
- Format check: `swiftformat --lint .`
- Format fix: `swiftformat .`
- **Run formatter before commit**

## Architecture

### Core Components
- **cggen**: CLI entry point using Swift Argument Parser
- **libcggen**: Main library for PDF/SVG → Core Graphics conversion
  - `PDFToDrawRouteConverter` / `SVGToDrawRouteConverter`: Convert input to DrawRoute
  - `BCCGGenerator` / `ObjCGen`: Generate bytecode or Objective-C code
  - `DrawRoute` / `PathRoutine`: Intermediate representation of graphics operations
- **CGGenRuntimeSupport**: Runtime library providing bytecode execution functions
  - Provides `runMergedBytecode_swift()` and `runPathBytecode_swift()` functions
  - Required dependency for generated Swift code

### Parser Architecture
The project uses swift-parsing library with custom operators:
- `~>>` / `<<~`: Skip left/right side
- `|`: Choice between parsers
- `~`: Sequence parsers
- `*` / `+`: Zero/one or more
- Custom parsers in `SVGAttributeParsers` for SVG attributes

**Swift-parsing reference**: Available combinators and parsers documented at https://pointfreeco.github.io/swift-parsing/main/documentation/parsing/parser

### Key Patterns
- **Functional composition**: Heavy use of `>>>` and `|>` operators
- **Protocol-oriented**: `GenerationStyle` for swift-friendly vs plain output
- **Concurrent processing**: `concurrentMap` for parallel file handling
- **Parser combinators**: All parsing logic uses declarative parser composition

## Development Workflow

### Testing Changes
1. Run `swift test` after any parser or generation changes
2. Regression tests compare generated output against expected results
3. Use `swift test --filter <test-name>` to run specific failing tests

### Common Tasks
- Add new SVG attribute: Update `SVGAttributeParsers.swift` and `SVGParsing.swift`
- Add new PDF operator: Update `PDFOperator.swift` and `PDFContentStreamParser.swift`
- Modify code generation: Update relevant files in `libcggen/`

### Migration Notes
Migration to swift-parsing library completed. Key changes made:
- Replaced custom `zip` functions with `Parse` builder syntax
- Removed legacy `OldParser` bridge infrastructure
- Use `Parse`, `OneOf`, `Many` builders for parser composition

## Test Framework Migration (Swift Testing)

### Key Principles
When migrating tests from XCTest to Swift Testing, follow these principles:
- **Minimal changes only**: Only change imports, declarations, and assertions
- **Preserve all logic**: Keep test structure, naming, and coverage identical
- **No verbose additions**: Don't add error messages or explanatory text to assertions
- **Keep it simple**: The goal is framework migration, not test improvement

### Migration Pattern
1. **Imports**: `import XCTest` → `import Testing`
2. **Test class/struct**: `class TestName: XCTestCase` → `@Suite struct TestName`
3. **Test methods**: `func testX()` → `@Test func testX()`
4. **Assertions**:
   - `XCTAssertEqual(a, b)` → `#expect(a == b)`
   - `XCTAssertNil(x)` → `#expect(x == nil)`
   - `XCTAssertNotNil(x)` → `#expect(x != nil)`
   - `XCTAssert(condition)` → `#expect(condition)`
   - `XCTFail()` → `Issue.record("message")`

### Parser Test Extensions
The codebase includes test helper extensions for parsers. These should be kept minimal:
```swift
extension NewParser where Input == Substring, Output: Equatable {
  func test(_ data: String, expected: (result: Output?, rest: String)) {
    var dataToParse = Substring(data)
    let res = Result { try parse(&dataToParse) }
    #expect(expected.result == res.value)
    #expect(expected.rest == String(dataToParse))
  }
}
```

### Important Notes
- Base.Parser conforms to NewParser, so it inherits test extensions automatically
- Don't duplicate extensions across test files
- Swift Testing requires `import Foundation` for `sqrt` and similar math functions
- Use `Issue.record()` instead of `XCTFail()` for recording test failures

## Parser Migration Completed

The migration from legacy parser infrastructure to swift-parsing is now complete:

**Completed work**:
- Replaced all `zip` function calls with `Parse` builder syntax
- Removed `OldParser` struct and bridge infrastructure
- Eliminated `.oldParser` extension usage throughout codebase
- Updated test files to use direct Parser types

**Key infrastructure**:
- `DicitionaryKey<Key, Value>: Parser` - Direct dictionary key extraction
- Custom parser operators (`~>>`, `<<~`, `~`, `*`, `+`, `~?`) for parsing DSL

## Project Memories
- Consider updating your project memory before finishing the task