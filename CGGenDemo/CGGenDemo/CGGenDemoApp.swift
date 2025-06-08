import ArgumentParser
import SwiftUI

enum DemoTab: String, CaseIterable, ExpressibleByArgument {
  case swiftui
  case appkit
  case playground
}

struct CLIArgs: ParsableArguments {
  @Option var tab: DemoTab = .swiftui

  // Capture all unrecognized arguments to prevent errors
  @Argument(parsing: .allUnrecognized) var unrecognized: [String] = []
}

@main
struct CGGenDemoApp: App {
  @State private var selectedTab: DemoTab

  init() {
    let args = CLIArgs.parseOrExit()
    _selectedTab = State(initialValue: args.tab)
  }

  var body: some Scene {
    WindowGroup {
      ContentView(selectedTab: $selectedTab)
    }
  }
}

struct ContentView: View {
  @Binding var selectedTab: DemoTab

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack {
        SwiftUIDemo()
      }
      .tabItem {
        Label("SwiftUI", systemImage: "swift")
      }
      .tag(DemoTab.swiftui)

      #if canImport(UIKit)
      NavigationStack {
        UIKitDemo()
      }
      .tabItem {
        Label("UIKit", systemImage: "uiwindow.split.2x1")
      }
      .tag(DemoTab.appkit)
      #elseif canImport(AppKit)
      NavigationStack {
        AppKitDemo()
      }
      .tabItem {
        Label("AppKit", systemImage: "macwindow")
      }
      .tag(DemoTab.appkit)
      #endif

      NavigationStack {
        PlaygroundView()
      }
      .tabItem {
        Label("Playground", systemImage: "paintbrush.pointed")
      }
      .tag(DemoTab.playground)
    }
  }
}

#Preview {
  ContentView(selectedTab: .constant(.swiftui))
}
