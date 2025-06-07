import CGGenRuntimeSupport
import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct PlatformGalleryView: View {
  @State private var contentMode: DrawingContentMode = .aspectFit
  @State private var targetSize: CGFloat = 100

  let columns = [
    GridItem(.adaptive(minimum: 150), spacing: 20),
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text(platformTitle)
          .font(.largeTitle)
          .padding(.top)

        Text("Using Platform-Specific Views")
          .font(.subheadline)
          .foregroundColor(.secondary)

        controlsView

        LazyVGrid(columns: columns, spacing: 20) {
          ForEach(["heart", "star", "gear"], id: \.self) { name in
            PlatformImageCell(
              name: name.capitalized,
              imageName: name,
              targetSize: CGSize(width: targetSize, height: targetSize),
              contentMode: contentMode
            )
          }
        }
        .padding()
      }
    }
    .navigationTitle(platformTitle)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  var platformTitle: String {
    #if os(iOS)
    "UIKit Demo"
    #else
    "AppKit Demo"
    #endif
  }

  var controlsView: some View {
    VStack(spacing: 15) {
      VStack(alignment: .leading) {
        Text("Content Mode")
          .font(.headline)
        Picker("Content Mode", selection: $contentMode) {
          Text("Aspect Fit").tag(DrawingContentMode.aspectFit)
          Text("Aspect Fill").tag(DrawingContentMode.aspectFill)
          Text("Scale to Fill").tag(DrawingContentMode.scaleToFill)
          Text("Center").tag(DrawingContentMode.center)
        }
        .pickerStyle(.segmented)
      }

      VStack(alignment: .leading) {
        Text("Size: \(Int(targetSize))pt")
          .font(.headline)
        Slider(value: $targetSize, in: 50...200, step: 10)
      }

      Text("Native \(platformTitle) views embedded in SwiftUI")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
    .padding(.horizontal)
  }
}

struct PlatformImageCell: View {
  let name: String
  let imageName: String
  let targetSize: CGSize
  let contentMode: DrawingContentMode

  var body: some View {
    VStack {
      Text(name)
        .font(.headline)

      ZStack {
        Rectangle()
          .fill(Color.gray.opacity(0.1))
          .border(Color.gray.opacity(0.3), width: 1)

        PlatformImageView(
          imageName: imageName,
          targetSize: targetSize,
          contentMode: contentMode
        )
      }
      .frame(width: targetSize.width, height: targetSize.height)

      VStack(spacing: 4) {
        Text("Content Mode: \(contentModeName)")
          .font(.caption2)
          .foregroundColor(.secondary)

        #if os(iOS)
        Text("UIImageView")
          .font(.caption2)
          .foregroundColor(.blue)
        #else
        Text("NSImageView")
          .font(.caption2)
          .foregroundColor(.blue)
        #endif
      }
    }
    .padding()
    .background(Color.white)
    .cornerRadius(10)
    .shadow(radius: 2)
  }

  var contentModeName: String {
    switch contentMode {
    case .aspectFit: return "Aspect Fit"
    case .aspectFill: return "Aspect Fill"
    case .scaleToFill: return "Scale to Fill"
    case .center: return "Center"
    default: return "Other"
    }
  }
}

#if os(iOS)
struct PlatformImageView: UIViewRepresentable {
  let imageName: String
  let targetSize: CGSize
  let contentMode: DrawingContentMode

  func makeUIView(context _: Context) -> UIImageView {
    let imageView = UIImageView()
    imageView.backgroundColor = .clear
    return imageView
  }

  func updateUIView(_ imageView: UIImageView, context _: Context) {
    let drawing = getDrawing(for: imageName)
    imageView.image = UIImage(
      drawing: drawing,
      size: targetSize,
      contentMode: contentMode
    )

    switch contentMode {
    case .aspectFit:
      imageView.contentMode = .scaleAspectFit
    case .aspectFill:
      imageView.contentMode = .scaleAspectFill
    case .scaleToFill:
      imageView.contentMode = .scaleToFill
    case .center:
      imageView.contentMode = .center
    default:
      imageView.contentMode = .scaleAspectFit
    }
  }

  func getDrawing(for name: String) -> Drawing {
    switch name {
    case "heart": return Drawing.heart
    case "star": return Drawing.star
    case "gear": return Drawing.gear
    default: return Drawing.heart
    }
  }
}
#else
struct PlatformImageView: NSViewRepresentable {
  let imageName: String
  let targetSize: CGSize
  let contentMode: DrawingContentMode

  func makeNSView(context _: Context) -> NSImageView {
    let imageView = NSImageView()
    imageView.imageFrameStyle = .none
    imageView.isEditable = false
    return imageView
  }

  func updateNSView(_ imageView: NSImageView, context _: Context) {
    let drawing = getDrawing(for: imageName)
    imageView.image = NSImage(
      drawing: drawing,
      size: targetSize,
      contentMode: contentMode
    )

    switch contentMode {
    case .aspectFit:
      imageView.imageScaling = .scaleProportionallyUpOrDown
    case .aspectFill:
      imageView.imageScaling = .scaleAxesIndependently
    case .scaleToFill:
      imageView.imageScaling = .scaleAxesIndependently
    case .center:
      imageView.imageScaling = .scaleNone
    default:
      imageView.imageScaling = .scaleProportionallyUpOrDown
    }
  }

  func getDrawing(for name: String) -> Drawing {
    switch name {
    case "heart": return Drawing.heart
    case "star": return Drawing.star
    case "gear": return Drawing.gear
    default: return Drawing.heart
    }
  }
}
#endif

#Preview {
  PlatformGalleryView()
}
