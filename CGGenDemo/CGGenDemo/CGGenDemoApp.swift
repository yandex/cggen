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
  enum Tab { case swiftUI, platform }
  @State private var selectedTab = Tab.swiftUI

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack {
        SwiftUIGalleryView()
      }
      .tabItem {
        Label("SwiftUI", systemImage: "swift")
      }
      .tag(Tab.swiftUI)

      NavigationStack {
        PlatformGalleryView()
      }
      .tabItem {
        #if os(iOS)
        Label("UIKit", systemImage: "uiwindow.split.2x1")
        #else
        Label("AppKit", systemImage: "macwindow")
        #endif
      }
      .tag(Tab.platform)
    }
  }
}

#Preview {
  ContentView()
}
