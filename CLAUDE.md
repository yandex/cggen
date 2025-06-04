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

## Architecture

### Core Components
- **cggen**: CLI entry point using Swift Argument Parser
- **libcggen**: Main library for PDF/SVG → Core Graphics conversion
  - `PDFToDrawRouteConverter` / `SVGToDrawRouteConverter`: Convert input to DrawRoute
  - `BCCGGenerator` / `ObjCGen`: Generate bytecode or Objective-C code
  - `DrawRoute` / `PathRoutine`: Intermediate representation of graphics operations

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
Currently migrating to swift-parsing library. Key changes:
- Replace `Parser<D, T>` with concrete parser types
- Update operators to return concrete types instead of existentials
- Use `Parse`, `OneOf`, `Many` builders instead of custom implementations

#### Removing .oldParser Usage
When eliminating `.oldParser` usage, follow these patterns:
- **Validation logic**: Convert `.oldParser.flatMapResult` to `.compactMap` with nil return for failures
- **Dictionary parsing**: Use `DicitionaryKey` struct directly instead of `key()` wrapper + `.oldParser`
- **Error handling**: Replace `Result { try parser.parse() }` with `try? parser.parse()` for optional results
- **Parser wrapping**: Use `OldParser(newParser)` when function must return `OldParser` type
- **One change at a time**: Make incremental changes and test each modification individually
- **Avoid complex conversions**: Skip enum case handling and pullback operations until simpler patterns are complete

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

## Legacy Code Removal

### .oldParser Extension Elimination
The codebase is gradually removing usage of the `.oldParser` extension that bridges NewParser to OldParser types. Progress tracking:

**Completed removals**:
- `version` parser in SVGParsing.swift (validation logic)
- Both `attributeParser` functions in SVGParsing.swift (dictionary parsing)

**Remaining areas** (as of latest update):
- Complex enum case handling in `element` functions
- Pullback operations with XML parsing
- Child parser compositions in `elementWithChildren`

**Infrastructure added**:
- `DicitionaryKey<Key, Value>: NewParser` - Direct dictionary key extraction without legacy wrappers