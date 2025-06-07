import CGGenRuntimeSupport
import SwiftUI

struct SwiftUIDemo: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 30) {
        Text("SwiftUI API Examples")
          .font(.largeTitle)
          .padding(.top)

        // Direct usage as SwiftUI Views
        Section("Direct View Usage") {
          HStack(spacing: 30) {
            Drawing.star
            Drawing.heart
            Drawing.gear
            Drawing.rocket
            Drawing.mountain
          }
        }

        // With SwiftUI modifiers
        Section("With Modifiers") {
          HStack(spacing: 20) {
            Drawing.heart
              .foregroundColor(.red)
              .frame(width: 50, height: 50)

            Drawing.star
              .foregroundColor(.yellow)
              .scaleEffect(1.5)

            Drawing.gear
              .foregroundColor(.gray)
              .rotationEffect(.degrees(45))
          }
        }

        // In buttons
        Section("In Buttons") {
          HStack(spacing: 20) {
            Button(action: {}) {
              Drawing.rocket
                .frame(width: 30, height: 30)
            }
            .buttonStyle(.borderedProminent)

            Button(action: {}) {
              HStack {
                Drawing.star
                  .frame(width: 20, height: 20)
                Text("Favorite")
              }
            }
            .buttonStyle(.bordered)
          }
        }

        // With aspect ratio
        Section("Aspect Ratio Examples") {
          HStack(spacing: 20) {
            Drawing.mountain
              .aspectRatio(contentMode: .fit)
              .frame(width: 100, height: 60)
              .border(Color.gray)

            Drawing.mountain
              .aspectRatio(contentMode: .fill)
              .frame(width: 100, height: 60)
              .clipped()
              .border(Color.gray)
          }
        }

        // As images
        Section("As SwiftUI Images") {
          HStack(spacing: 20) {
            Image(drawing: .gear)
              .resizable()
              .frame(width: 40, height: 40)

            Image(drawing: .star, scale: 2.0)
              .foregroundColor(.orange)
          }
        }
      }
      .padding()
    }
    .navigationTitle("SwiftUI API")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

// Helper view for sections
struct Section<Content: View>: View {
  let title: String
  let content: () -> Content

  init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.headline)

      content()
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
  }
}

#Preview {
  SwiftUIDemo()
}
