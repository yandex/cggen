import AppKit

let images = parse(scale: 10)

extension CGImage {
  func size() -> CGSize {
    return CGSize(width: width, height: height)
  }
}

let nsimages = images.map { (image) -> NSImage in
  return NSImage(cgImage: image, size: image.size())
}

print(nsimages)
