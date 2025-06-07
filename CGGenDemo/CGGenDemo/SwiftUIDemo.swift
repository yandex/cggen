import CGGenRuntimeSupport
import SwiftUI

struct SwiftUIDemo: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15) {
        Text("SwiftUI API Examples")
          .font(.title3)
          .padding(.top, 10)

        // Direct usage as SwiftUI Views
        Section("Direct View Usage") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Drawings conform to View protocol")
              .font(.caption)
              .foregroundColor(.secondary)

            HStack(spacing: 10) {
              Drawing.star
                .frame(width: 16, height: 16)
              Drawing.heart
                .frame(width: 16, height: 16)
              Drawing.gear
                .frame(width: 16, height: 16)
              Drawing.rocket
                .frame(width: 24, height: 24)
              Drawing.mountain
                .frame(width: 30, height: 24)
            }
          }
        }

        // With SwiftUI modifiers
        Section("With Modifiers") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Works with standard SwiftUI modifiers")
              .font(.caption)
              .foregroundColor(.secondary)

            HStack(spacing: 10) {
              Drawing.heart
                .foregroundColor(.red)
                .frame(width: 16, height: 16)

              Drawing.star
                .foregroundColor(.yellow)
                .frame(width: 16, height: 16)
                .scaleEffect(1.2)

              Drawing.gear
                .foregroundColor(.gray)
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(45))
            }
          }
        }

        // In buttons
        Section("In Buttons") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Use directly in button labels")
              .font(.caption)
              .foregroundColor(.secondary)

            HStack(spacing: 10) {
              Button(action: {}) {
                Drawing.rocket
                  .frame(width: 14, height: 14)
              }
              .buttonStyle(.borderedProminent)

              Button(action: {}) {
                HStack(spacing: 4) {
                  Drawing.star
                    .frame(width: 12, height: 12)
                  Text("Favorite")
                    .font(.caption)
                }
              }
              .buttonStyle(.bordered)
            }
          }
        }

        // With aspect ratio
        Section("Aspect Ratio Examples") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Standard aspect ratio modifiers")
              .font(.caption)
              .foregroundColor(.secondary)

            HStack(spacing: 10) {
              VStack(spacing: 4) {
                Drawing.mountain
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 40, height: 30)
                  .border(Color.gray, width: 0.5)
                Text("Fit")
                  .font(.caption2)
              }

              VStack(spacing: 4) {
                Drawing.mountain
                  .aspectRatio(contentMode: .fill)
                  .frame(width: 40, height: 30)
                  .clipped()
                  .border(Color.gray, width: 0.5)
                Text("Fill")
                  .font(.caption2)
              }
            }
          }
        }

        // As images
        Section("As SwiftUI Images") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Convert to Image for more control")
              .font(.caption)
              .foregroundColor(.secondary)

            HStack(spacing: 10) {
              Image(drawing: .gear)
                .resizable()
                .frame(width: 16, height: 16)

              Image(drawing: .star, scale: 2.0)
                .foregroundColor(.orange)
                .frame(width: 16, height: 16)
            }
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
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.subheadline)
        .fontWeight(.semibold)

      content()
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
  }
}

#Preview {
  SwiftUIDemo()
}
