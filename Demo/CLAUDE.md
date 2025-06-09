# Demo Workflow

This document helps Claude Code work with the Demo app effectively.

## Overview

Demo is a demonstration app showcasing cggen's drawing APIs across SwiftUI, AppKit, and a playground environment. The app accepts command-line arguments to launch directly into specific tabs.

## Tabs

- **SwiftUI/AppKit/UIKit tabs**: Show code examples of cggen API usage with live previews, organized by categories like image creation, sizing, and UI integration.
- **Playground tab**: Interactive environment for testing different drawings with adjustable size, content mode, and scale settings.

## Command Line Arguments

- `--tab [swiftui|appkit|playground]` - Launch with specific tab (default: swiftui)

## Building and Running

To build and run Demo, use these MCP tools in sequence:

1. **Build the app**
   - Tool: `mcp__XcodeBuildMCP__build_mac_proj`
   - projectPath: `/Users/alfred/dev/cggen/Demo/Demo.xcodeproj`
   - scheme: `Demo`

2. **Get the built app path**
   - Tool: `mcp__XcodeBuildMCP__get_mac_app_path_proj`
   - projectPath: `/Users/alfred/dev/cggen/Demo/Demo.xcodeproj`
   - scheme: `Demo`

3. **Launch the app**
   - Tool: `mcp__XcodeBuildMCP__launch_mac_app`
   - appPath: (path from step 2)
   - args: (optional, e.g. `["--tab", "appkit"]`)

## Taking Screenshots

### Screenshot workflow
1. Launch app with desired tab
2. Remove any existing screenshot file if present
3. Capture screenshot immediately without sleep/delay:

```bash
shortcuts run "cggendemo" --output-path .claude_temp/screenshot_name.png
```

### Screenshot storage
- Screenshots are saved in `.claude_temp/` folder
- This folder is gitignored to keep the repository clean
- Always remove old screenshots before capturing new ones

### Shortcuts Setup
- The `cggendemo.shortcut` file is included in this folder
- Import it to macOS Shortcuts app if needed
- This shortcut captures the Demo window and outputs PNG data

## Demo App Architecture

- **SwiftUI tab**: Shows SwiftUI API usage with Drawing views
- **AppKit tab**: Shows AppKit/NSImage API usage  
- **Playground tab**: Interactive demo for testing different drawings and sizes

## Key Fixes Applied

1. **Drawing view scaling**: Fixed to respect frame constraints
2. **Coordinate system**: Fixed upside-down images in SwiftUI by flipping Canvas coordinates
3. **AppKit layout**: Using FlippedView for correct coordinate system
4. **UI sizing**: Icons at 16pt, larger drawings at 24-40pt for better visual hierarchy