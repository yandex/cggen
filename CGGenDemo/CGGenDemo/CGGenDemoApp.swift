import SwiftUI

@main
struct CGGenDemoApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  var body: some View {
    TabView {
      NavigationStack {
        SwiftUIDemo()
      }
      .tabItem {
        Label("SwiftUI", systemImage: "swift")
      }
      .tag(0)

      #if canImport(UIKit)
      NavigationStack {
        UIKitDemo()
      }
      .tabItem {
        Label("UIKit", systemImage: "uiwindow.split.2x1")
      }
      .tag(1)
      #elseif canImport(AppKit)
      NavigationStack {
        AppKitDemo()
      }
      .tabItem {
        Label("AppKit", systemImage: "macwindow")
      }
      .tag(1)
      #endif

      NavigationStack {
        PlaygroundView()
      }
      .tabItem {
        Label("Playground", systemImage: "paintbrush.pointed")
      }
      .tag(2)
    }
  }
}

#Preview {
  ContentView()
}
