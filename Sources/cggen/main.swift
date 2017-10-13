import AppKit
import Foundation

let routes = CommandLine.arguments
  .map { URL(fileURLWithPath: $0) }
  .map { ($0.deletingPathExtension().lastPathComponent, parse(pdfURL: $0 as CFURL)) }

extension CGImage {
  func size() -> CGSize {
    return CGSize(width: width, height: height)
  }
}

extension DrawRoute {
  func drawNSImage() -> NSImage {
    let cgImage = self.draw(scale: 10)
    return NSImage(cgImage: cgImage, size: cgImage.size())
  }
}

let images = routes
  .flatMap { $0.1.map { (route) -> NSImage in route.drawNSImage() }
}

let impl = routes.map { (arg) -> String in
  let (name, routes) = arg
  return routes.enumerated().map({ (offset, route) -> String in
    let finalName = name + (offset == 0 ? "" : "_\(offset)")
    let implCommands = ObjCCGCommandProvider(prefix: "YDA")
    return route.genCGCode(imageName: finalName, commands: implCommands)
  }).joined(separator: "\n\n")
}.joined(separator: "\n\n")

let header = routes.map { (arg) -> String in
  let (name, routes) = arg
  return routes.enumerated().map({ (offset, route) -> String in
    let finalName = name + (offset == 0 ? "" : "_\(offset)")
    let implCommands = ObjCCGCommandProviderHeader(prefix: "YDA")
    return route.genCGCode(imageName: finalName, commands: implCommands)
  }).joined(separator: "\n\n")
}.joined(separator: "\n\n")

print(header)
print(impl)
