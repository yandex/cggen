# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@~/.claude/cggen.md

## Quick Reference

### Essential Commands
```bash
# Build
swift build --product cggen

# Test
swift test
swift test --parallel
swift test --filter <test-name>

# Format
swiftformat --lint .
swiftformat .

# Run CLI
swift run cggen --swift-output Generated.swift *.svg *.pdf

# Run demos
swift run plugin-demo
open Demo/Demo.xcodeproj
```

### File Naming Conventions
- Swift files: PascalCase (e.g., `SVGRenderer.swift`)
- Documentation: dash-separated lowercase (e.g., `api-usage-guide.md`)
- Test samples: underscore-separated lowercase (e.g., `gradient_with_alpha.svg`)

## IMPORTANT: Testing Requirements
- **ALWAYS run `swift test` after making code changes**
- **NEVER consider a task complete without running tests**
- **Before marking any coding task as complete:**
  1. Run `swift test`
  2. Run `swiftformat --lint .` 
  3. Verify the build works
- **If tests fail, fix them before proceeding**

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
- Extended tests (WebKit reference generation): `CGGEN_EXTENDED_TESTS=1 swift test`

#### Snapshot Testing
- Update snapshots: `SNAPSHOT_TESTING_RECORD=all swift test`
- Update only failed snapshots: `SNAPSHOT_TESTING_RECORD=failed swift test`
- Update only missing snapshots: `SNAPSHOT_TESTING_RECORD=missing swift test` (default)
- Never record snapshots: `SNAPSHOT_TESTING_RECORD=never swift test`
- Update all reference snapshots: `CGGEN_EXTENDED_TESTS=1 SNAPSHOT_TESTING_RECORD=all swift test --filter "SVGReferencesTests"`

#### Extended Tests
- WebKit reference generation tests are disabled by default
- Enable with: `CGGEN_EXTENDED_TESTS=1 swift test`
- The `extendedTestsEnabled` constant in `SVGTests.swift` controls this behavior

#### Debug Output
- Save test failure images: `CGGEN_TEST_DEBUG_OUTPUT=/path/to/debug/dir swift test`
- When tests fail, saves reference.png, result.png, diff.png and info.json to the specified directory
- Useful for debugging visual differences between expected and actual output

### Lint and Type Checking
- Format check: `swiftformat --lint .`
- Format fix: `swiftformat .`
- **Run formatter before commit**

### CI/CD
- **Main workflow**: Runs on every push/PR with deterministic hashing
- **Nightly Extended Test Suite**: Runs at 2 AM UTC if there are new commits
  - Tests bytecode determinism without `SWIFT_DETERMINISTIC_HASHING`
  - Runs gradient determinism test 5 times
  - Runs all tests once with `CGGEN_EXTENDED_TESTS=1` (includes WebKit reference generation)
  - Creates GitHub issue if tests fail
  - Can be manually triggered from GitHub Actions UI

### Run
- Use `swift run` to run executables

## Architecture

### Core Components
- **cggen**: CLI entry point using Swift Argument Parser
- **CGGenCLI**: Main library for PDF/SVG → Core Graphics conversion
  - `PDFToDrawRouteConverter` / `SVGToDrawRouteConverter`: Convert input to DrawRoute
  - `MBCCGGenerator` / `ObjCGen` / `SwiftCGGenerator`: Generate bytecode, Objective-C, or Swift code
  - `DrawRoute` / `PathRoutine`: Intermediate representation of graphics operations
- **CGGenIR**: Intermediate representation and bytecode generation
  - `DrawStep` / `PathSegment`: Low-level drawing operations
  - `BytecodeGeneration`: Compiles IR to compressed bytecode
- **CGGenRuntime**: Runtime library for parsing and rendering SVG/PDF directly
  - `SVGRenderer`: Direct SVG rendering without code generation
  - `SVGSupport`: Runtime SVG parsing and rendering utilities
  - Can be used to render graphics at runtime without code generation
- **CGGenRTSupport**: Bytecode execution library
  - Provides `Drawing` type used by generated Swift code
  - `BytecodeRunner`: Executes compressed bytecode to draw on CGContext
  - Platform-specific image support (UIKit/AppKit)
  - Required dependency for apps using cggen-generated code
- **SVGParse**: SVG parsing infrastructure
  - Parser combinators for SVG attributes and elements
  - Color, gradient, filter, and shape parsing
- **PDFParse**: PDF parsing infrastructure
  - PDF object model and content stream parsing
  - Support for graphics operators, resources, and functions

### Parser Architecture
The project uses swift-parsing library with custom operators:
- `~>>` / `<<~`: Skip left/right side
- `|`: Choice between parsers
- `~`: Sequence parsers
- `*` / `+`: Zero/one or more
- Custom parsers in `SVGValueParser` for SVG attributes

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
- Add new SVG attribute: Update `SVGValueParser.swift` and `SVGParsing.swift`
- Add new PDF operator: Update `PDFOperator.swift` and `PDFContentStreamParser.swift`
- Modify code generation: Update relevant files in `CGGenCLI/`
- Add runtime rendering support: Update `SVGRenderer.swift` and `SVGSupport.swift`
- Modify bytecode generation: Update `BytecodeGeneration.swift` in `CGGenIR/`

### Migration Notes
Migration to swift-parsing library completed. Key changes made:
- Replaced custom `zip` functions with `Parse` builder syntax
- Removed legacy `OldParser` bridge infrastructure
- Use `Parse`, `OneOf`, `Many` builders for parser composition


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

## Documentation

### Available Documentation
- [docs/architecture.md](docs/architecture.md) - Detailed architecture overview
- [docs/api-usage-guide.md](docs/api-usage-guide.md) - API usage examples
- [docs/api-design-considerations.md](docs/api-design-considerations.md) - Design rationale
- [docs/adding-new-attribute.md](docs/adding-new-attribute.md) - Contributing guide for SVG attributes
- [docs/path-generation.md](docs/path-generation.md) - Path extraction feature guide

### Key File Locations
- **CLI Entry**: `Sources/cggen/main.swift`
- **Main Logic**: `Sources/CGGenCLI/`
- **Runtime Support**: `Sources/CGGenRTSupport/`
- **SVG Parsing**: `Sources/SVGParse/`
- **PDF Parsing**: `Sources/PDFParse/`
- **SPM Plugin**: `Plugins/CGGenPlugin/`
- **Tests**: `Tests/` (Unit, Regression, CGGen tests)

## Demo App

See [Demo/CLAUDE.md](Demo/CLAUDE.md) for detailed workflow documentation including:
- Command line arguments for tab selection
- Screenshot capture workflow using `.claude_temp` folder
- Building and running instructions
- Architecture notes and key fixes

## Project Memories
- Consider updating your project memory before finishing the task
- Launch xcodebuild with -quiet option if not strongly necessary otherwise
- ALWAYS use .claude_temp folder for temporary files, NEVER use /tmp or temp directories
- Extended tests (like WebKit reference generation) are controlled by `CGGEN_EXTENDED_TESTS=1` environment variable
- The `extendedTestsEnabled` constant is defined at the bottom of SVGTests.swift and can be used to skip tests that should only run in extended mode

## Project Guidelines
- AVOID marketing tone of new changes in documentation