import CGGenRuntimeSupport
import SwiftUI

struct SwiftUIDemo: View {
  var body: some View {
    List {
      // Direct Drawing usage
      Section("Drawing as View") {
        HStack {
          Drawing.star
            .frame(width: 30, height: 30)
          Spacer()
          Text("Drawing.star")
        }

        HStack {
          Drawing.heart
            .foregroundColor(.red)
            .frame(width: 30, height: 30)
          Spacer()
          Text("Drawing.heart.foregroundColor(.red)")
        }
      }

      // Frame and sizing
      Section("Sizing") {
        HStack {
          Drawing.gear
            .frame(width: 30, height: 30)
          Spacer()
          Text(".frame(width: 30, height: 30)")
        }

        HStack {
          Drawing.mountain
            .aspectRatio(contentMode: .fit)
            .frame(height: 40)
            .background(Color.gray.opacity(0.1))
          Spacer()
          Text(".aspectRatio(contentMode: .fit)")
        }
      }

      // Image conversion
      Section("Image(drawing:)") {
        HStack {
          Image(drawing: .rocket)
            .resizable()
            .frame(width: 30, height: 30)
          Spacer()
          Text("Image(drawing: .rocket).resizable()")
        }

        HStack {
          Image(drawing: .star, scale: 2.0)
            .foregroundColor(.orange)
          Spacer()
          Text("Image(drawing: .star, scale: 2.0)")
        }
      }

      // Modifiers
      Section("Modifiers") {
        HStack {
          Drawing.gear
            .rotationEffect(.degrees(45))
            .frame(width: 30, height: 30)
          Spacer()
          Text(".rotationEffect(.degrees(45))")
        }

        HStack {
          Drawing.heart
            .scaleEffect(1.5)
            .foregroundColor(.pink)
            .frame(width: 45, height: 45)
          Spacer()
          Text(".scaleEffect(1.5)")
        }

        HStack {
          Drawing.rocket
            .opacity(0.5)
            .frame(width: 30, height: 30)
          Spacer()
          Text(".opacity(0.5)")
        }
      }

      // In buttons
      Section("Interactive") {
        HStack {
          Button(action: {}) {
            Drawing.star
              .frame(width: 20, height: 20)
          }
          .buttonStyle(.bordered)
          Spacer()
          Text("Button with Drawing")
        }

        HStack {
          Button(action: {}) {
            Label {
              Text("Navigate")
            } icon: {
              Drawing.mountain
                .frame(width: 16, height: 16)
            }
          }
          .buttonStyle(.borderedProminent)
          Spacer()
          Text("Label with icon")
        }
      }
    }
    .navigationTitle("SwiftUI API")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

#Preview {
  SwiftUIDemo()
}
