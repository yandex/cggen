#if canImport(SwiftUI)
import SwiftUI

struct SwiftUIExample: View {
  var body: some View {
    VStack(spacing: 20) {
      Text("cggen SwiftUI Example")
        .font(.title)

      // Direct usage as SwiftUI Views
      HStack(spacing: 30) {
        Drawing.circle
          .foregroundColor(.blue)

        Drawing.square
          .foregroundColor(.green)

        Drawing.star
          .foregroundColor(.orange)
      }

      // With standard modifiers
      Drawing.star
        .frame(width: 60, height: 60)
        .foregroundColor(.yellow)
        .shadow(radius: 2)

      // In buttons
      Button(action: {}) {
        HStack {
          Drawing.circle
            .frame(width: 20, height: 20)
          Text("Button")
        }
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }
}

#Preview {
  SwiftUIExample()
}
#endif
