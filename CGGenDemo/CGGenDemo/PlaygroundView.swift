import CGGenRuntimeSupport
import SwiftUI

struct PlaygroundView: View {
  @State private var selectedDrawing: DrawingType = .star
  @State private var targetWidth: CGFloat = 100
  @State private var targetHeight: CGFloat = 100
  @State private var contentMode: DrawingContentMode = .aspectFit
  @State private var scale: CGFloat = 2.0
  @State private var showBounds = true
  @State private var backgroundColor = Color.white

  enum DrawingType: String, CaseIterable {
    case star = "Star"
    case heart = "Heart"
    case gear = "Gear"
    case rocket = "Rocket"
    case mountain = "Mountain"

    var drawing: Drawing {
      switch self {
      case .star: return .star
      case .heart: return .heart
      case .gear: return .gear
      case .rocket: return .rocket
      case .mountain: return .mountain
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 30) {
        Text("Interactive Playground")
          .font(.largeTitle)
          .padding(.top)

        // Preview area
        VStack {
          Text("Preview")
            .font(.headline)

          ZStack {
            Rectangle()
              .fill(backgroundColor)
              .frame(width: targetWidth, height: targetHeight)

            if showBounds {
              Rectangle()
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(width: targetWidth, height: targetHeight)
            }

            // Show the drawing with current settings
            generateImage()
              .resizable()
              .renderingMode(.original)
              .frame(width: targetWidth, height: targetHeight)
          }
          .frame(maxWidth: 300, maxHeight: 300)

          HStack {
            Text(
              "Original: \(Int(selectedDrawing.drawing.size.width))×\(Int(selectedDrawing.drawing.size.height))"
            )
            Text("•")
            Text("Target: \(Int(targetWidth))×\(Int(targetHeight))")
          }
          .font(.caption)
          .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)

        // Controls
        VStack(spacing: 20) {
          // Drawing picker
          VStack(alignment: .leading) {
            Text("Drawing")
              .font(.headline)
            Picker("Drawing", selection: $selectedDrawing) {
              ForEach(DrawingType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
              }
            }
            .pickerStyle(.segmented)
          }

          // Size controls
          VStack(alignment: .leading) {
            Text("Target Size")
              .font(.headline)

            HStack {
              Text("Width:")
              Slider(value: $targetWidth, in: 20...300, step: 10)
              Text("\(Int(targetWidth))pt")
                .monospacedDigit()
                .frame(width: 50)
            }

            HStack {
              Text("Height:")
              Slider(value: $targetHeight, in: 20...300, step: 10)
              Text("\(Int(targetHeight))pt")
                .monospacedDigit()
                .frame(width: 50)
            }

            Button("Reset to Square") {
              let size = max(targetWidth, targetHeight)
              targetWidth = size
              targetHeight = size
            }
            .font(.caption)
          }

          // Content mode
          VStack(alignment: .leading) {
            Text("Content Mode")
              .font(.headline)

            VStack(spacing: 10) {
              HStack {
                contentModeButton(.scaleToFill, "Scale to Fill")
                contentModeButton(.aspectFit, "Aspect Fit")
              }
              HStack {
                contentModeButton(.aspectFill, "Aspect Fill")
                contentModeButton(.center, "Center")
              }
              HStack {
                contentModeButton(.top, "Top")
                contentModeButton(.bottom, "Bottom")
              }
              HStack {
                contentModeButton(.left, "Left")
                contentModeButton(.right, "Right")
              }
              HStack {
                contentModeButton(.topLeft, "Top Left")
                contentModeButton(.topRight, "Top Right")
              }
              HStack {
                contentModeButton(.bottomLeft, "Bottom Left")
                contentModeButton(.bottomRight, "Bottom Right")
              }
            }
          }

          // Scale factor
          VStack(alignment: .leading) {
            Text("Scale Factor")
              .font(.headline)
            HStack {
              Slider(value: $scale, in: 0.5...4.0, step: 0.5)
              Text("\(scale, specifier: "%.1f")x")
                .monospacedDigit()
                .frame(width: 50)
            }
          }

          // Visual options
          VStack(alignment: .leading) {
            Text("Visual Options")
              .font(.headline)

            Toggle("Show Bounds", isOn: $showBounds)

            HStack {
              Text("Background:")
              Spacer()
              ColorPicker("", selection: $backgroundColor)
                .labelsHidden()
            }
          }
        }
        .padding()

        // Code example
        VStack(alignment: .leading) {
          Text("Generated Code")
            .font(.headline)

          Text(generateCodeExample())
            .font(.system(.caption, design: .monospaced))
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .textSelection(.enabled)
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

  private func contentModeButton(
    _ mode: DrawingContentMode,
    _ title: String
  ) -> some View {
    Button(action: { contentMode = mode }) {
      Text(title)
        .font(.caption)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
          contentMode == mode ? Color.accentColor : Color.gray
            .opacity(0.2)
        )
        .foregroundColor(contentMode == mode ? .white : .primary)
        .cornerRadius(6)
    }
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

  private func generateCodeExample() -> String {
    let sizeStr = targetWidth == targetHeight
      ? "\(Int(targetWidth))"
      : "width: \(Int(targetWidth)), height: \(Int(targetHeight))"

    #if canImport(UIKit)
    return """
    // UIKit
    let image = UIImage(
      drawing: .\(selectedDrawing.rawValue.lowercased()),
      size: CGSize(\(sizeStr)),
      contentMode: .\(contentModeString),
      scale: \(scale)
    )

    // Or using KeyPath syntax
    let image = UIImage.draw(
      \\.\(selectedDrawing.rawValue.lowercased()),
      size: CGSize(\(sizeStr)),
      contentMode: .\(contentModeString),
      scale: \(scale)
    )
    """
    #else
    return """
    // AppKit
    let image = NSImage(
      drawing: .\(selectedDrawing.rawValue.lowercased()),
      size: CGSize(\(sizeStr)),
      contentMode: .\(contentModeString),
      scale: \(scale)
    )

    // Or using KeyPath syntax
    let image = NSImage.draw(
      \\.\(selectedDrawing.rawValue.lowercased()),
      size: CGSize(\(sizeStr)),
      contentMode: .\(contentModeString),
      scale: \(scale)
    )
    """
    #endif
  }

  private var contentModeString: String {
    switch contentMode {
    case .scaleToFill: return "scaleToFill"
    case .aspectFit: return "aspectFit"
    case .aspectFill: return "aspectFill"
    case .center: return "center"
    case .top: return "top"
    case .bottom: return "bottom"
    case .left: return "left"
    case .right: return "right"
    case .topLeft: return "topLeft"
    case .topRight: return "topRight"
    case .bottomLeft: return "bottomLeft"
    case .bottomRight: return "bottomRight"
    @unknown default: return "aspectFit"
    }
  }
}

#Preview {
  PlaygroundView()
}
