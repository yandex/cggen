import CGGenBytecode
import SwiftUI

struct PlaygroundView: View {
  @State private var selectedDrawing: DrawingType = .star
  @State private var targetWidth: CGFloat = 100
  @State private var targetHeight: CGFloat = 100
  @State private var contentMode: DrawingContentMode = .aspectFit
  @State private var scale: CGFloat = 2.0

  enum DrawingType: String, CaseIterable {
    case star = "Star"
    case heart = "Heart"
    case gear = "Gear"
    case rocket = "Rocket"
    case mountain = "Mountain"

    var drawing: Drawing {
      switch self {
      case .star: .star
      case .heart: .heart
      case .gear: .gear
      case .rocket: .rocket
      case .mountain: .mountain
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Preview area
        VStack(spacing: 8) {
          ZStack {
            Rectangle()
              .fill(Color.white)
              .frame(width: targetWidth, height: targetHeight)
              .overlay(
                Rectangle()
                  .stroke(Color.gray.opacity(0.3), lineWidth: 1)
              )

            // Show the drawing with current settings
            generateImage()
              .resizable()
              .renderingMode(.original)
              .frame(width: targetWidth, height: targetHeight)
          }
          .frame(maxWidth: 200, maxHeight: 200)

          Text(
            "Original: \(Int(selectedDrawing.drawing.size.width))×\(Int(selectedDrawing.drawing.size.height))"
          )
          .font(.caption2)
          .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)

        // Compact controls
        VStack(spacing: 16) {
          // Drawing picker inline with label
          HStack {
            Text("Image:")
              .font(.subheadline)
              .frame(width: 60, alignment: .leading)

            Picker("", selection: $selectedDrawing) {
              ForEach(DrawingType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
              }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
          }

          // Size controls - both sliders on one line
          HStack(spacing: 12) {
            Text("W:")
              .font(.caption)
            Slider(value: $targetWidth, in: 20...300, step: 10)
              .frame(maxWidth: 100)
            Text("\(Int(targetWidth))")
              .font(.caption)
              .monospacedDigit()
              .frame(width: 30)

            Text("H:")
              .font(.caption)
            Slider(value: $targetHeight, in: 20...300, step: 10)
              .frame(maxWidth: 100)
            Text("\(Int(targetHeight))")
              .font(.caption)
              .monospacedDigit()
              .frame(width: 30)

            Button("◻") {
              let size = max(targetWidth, targetHeight)
              targetWidth = size
              targetHeight = size
            }
            .font(.system(size: 18))
            .help("Make square")
          }

          // Content mode - two rows
          VStack(alignment: .leading, spacing: 6) {
            Text("Content Mode")
              .font(.subheadline)

            // Main content modes
            HStack(spacing: 4) {
              ForEach([
                ("Scale to Fill", DrawingContentMode.scaleToFill),
                ("Aspect Fit", .aspectFit),
                ("Aspect Fill", .aspectFill),
                ("Center", .center),
              ], id: \.0) { label, mode in
                Button(action: { contentMode = mode }) {
                  Text(label)
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                      contentMode == mode ? Color.accentColor : Color.gray
                        .opacity(0.2)
                    )
                    .foregroundColor(contentMode == mode ? .white : .primary)
                    .cornerRadius(4)
                }
              }
            }

            // Directional modes with arrows
            HStack(spacing: 4) {
              ForEach([
                ("↑", DrawingContentMode.top),
                ("↓", .bottom),
                ("←", .left),
                ("→", .right),
                ("↖", .topLeft),
                ("↗", .topRight),
                ("↙", .bottomLeft),
                ("↘", .bottomRight),
              ], id: \.0) { label, mode in
                Button(action: { contentMode = mode }) {
                  Text(label)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                      contentMode == mode ? Color.accentColor : Color.gray
                        .opacity(0.2)
                    )
                    .foregroundColor(contentMode == mode ? .white : .primary)
                    .cornerRadius(4)
                }
              }
            }
          }

          // Scale factor inline
          HStack {
            Text("Scale:")
              .font(.subheadline)
              .frame(width: 60, alignment: .leading)

            Slider(value: $scale, in: 0.5...4.0, step: 0.5)

            Text("\(scale, specifier: "%.1f")x")
              .font(.caption)
              .monospacedDigit()
              .frame(width: 35)
          }
        }
        .padding(.horizontal)
      }
      .padding(.horizontal)
    }
    .navigationTitle("Playground")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  private func generateImage() -> Image {
    #if canImport(UIKit)
    let platformImage = UIImage(
      drawing: selectedDrawing.drawing,
      size: CGSize(width: targetWidth, height: targetHeight),
      contentMode: contentMode,
      scale: scale
    )
    return Image(uiImage: platformImage)
    #elseif canImport(AppKit)
    let platformImage = NSImage(
      drawing: selectedDrawing.drawing,
      size: CGSize(width: targetWidth, height: targetHeight),
      contentMode: contentMode,
      scale: scale
    )
    return Image(nsImage: platformImage)
    #endif
  }
}

#Preview {
  PlaygroundView()
}
