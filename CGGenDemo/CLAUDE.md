# CLAUDE.md - CGGenDemo Workflow

This file documents the workflow for working with the CGGenDemo app.

## Command Line Arguments

The app supports launching with specific tabs using ArgumentParser:

```bash
# Launch with SwiftUI tab
--tab swiftui

# Launch with AppKit tab  
--tab appkit

# Launch with Playground tab
--tab playground
```

## Building and Running

### Build the app
```bash
xcodebuild -project CGGenDemo/CGGenDemo.xcodeproj -scheme CGGenDemo build
```

### Launch with specific tab
```bash
# Using Xcode MCP tool
mcp__XcodeBuildMCP__launch_mac_app --appPath <path_to_app> --args ["--tab", "swiftui"]
```

## Taking Screenshots

### Screenshot workflow
1. Launch app with desired tab
2. Use the macOS Shortcuts app to capture screenshots:

```bash
# Save screenshot to .claude_temp folder
shortcuts run "cggendemo" --output-path .claude_temp/screenshot_name.png
```

### Screenshot storage
- Screenshots are saved in `.claude_temp/` folder
- This folder is gitignored to keep the repository clean
- No need to clutter Desktop with temporary files

### Shortcuts Setup
- The `cggendemo.shortcut` file is included in this folder
- Import it to macOS Shortcuts app if needed
- This shortcut captures the CGGenDemo window and outputs PNG data

## Demo App Architecture

- **SwiftUI tab**: Shows SwiftUI API usage with Drawing views
- **AppKit tab**: Shows AppKit/NSImage API usage  
- **Playground tab**: Interactive demo for testing different drawings and sizes

## Key Fixes Applied

1. **Drawing view scaling**: Fixed to respect frame constraints
2. **Coordinate system**: Fixed upside-down images in SwiftUI by flipping Canvas coordinates
3. **AppKit layout**: Using FlippedView for correct coordinate system
4. **UI sizing**: Icons at 16pt, larger drawings at 24-40pt for better visual hierarchy