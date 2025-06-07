import CGGenRuntimeSupport
import SwiftUI

struct SwiftUIGalleryView: View {
  @State private var contentMode: ContentMode = .fit
  @State private var targetSize: CGFloat = 100

  let drawings: [(name: String, drawing: Drawing)] = [
    ("Heart", Drawing.heart),
    ("Star", Drawing.star),
    ("Gear", Drawing.gear),
  ]

  let columns = [
    GridItem(.adaptive(minimum: 150), spacing: 20),
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("SwiftUI Demo")
          .font(.largeTitle)
          .padding(.top)

        Text("Using cggen SPM Plugin")
          .font(.subheadline)
          .foregroundColor(.secondary)

        controlsView

        LazyVGrid(columns: columns, spacing: 20) {
          ForEach(drawings, id: \.name) { item in
            DrawingCell(
              name: item.name,
              drawing: item.drawing,
              targetSize: CGSize(width: targetSize, height: targetSize),
              contentMode: contentMode
            )
          }
        }
        .padding()
      }
    }
    .navigationTitle("SwiftUI Demo")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  var controlsView: some View {
    VStack(spacing: 15) {
      VStack(alignment: .leading) {
        Text("Content Mode")
          .font(.headline)
        Picker("Content Mode", selection: $contentMode) {
          Text("Fit").tag(ContentMode.fit)
          Text("Fill").tag(ContentMode.fill)
        }
        .pickerStyle(.segmented)
      }

      VStack(alignment: .leading) {
        Text("Size: \(Int(targetSize))pt")
          .font(.headline)
        Slider(value: $targetSize, in: 50...200, step: 10)
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
    .padding(.horizontal)
  }
}

struct DrawingCell: View {
  let name: String
  let drawing: Drawing
  let targetSize: CGSize
  let contentMode: ContentMode

  var body: some View {
    VStack {
      Text(name)
        .font(.headline)

      ZStack {
        Rectangle()
          .fill(Color.gray.opacity(0.1))
          .border(Color.gray.opacity(0.3), width: 1)

        drawing
          .aspectRatio(contentMode: contentMode)
          .frame(width: targetSize.width, height: targetSize.height)
          .clipped()
      }
      .frame(width: targetSize.width, height: targetSize.height)

      Text("Original: \(Int(drawing.size.width))×\(Int(drawing.size.height))")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color.white)
    .cornerRadius(10)
    .shadow(radius: 2)
  }
}

#Preview {
  SwiftUIGalleryView()
}
