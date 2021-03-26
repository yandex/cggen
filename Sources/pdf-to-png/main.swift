import Foundation
import Base
import ArgumentParser

struct Main: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "pdf-to-png",
    abstract: "Tool for converting pdf to png",
    version: "0.1"
  )
  @Option var out = ""
  @Option var scale = 1.0
  @Option var suffix = ""
  @Argument var files: [String] = []

  func run() throws {
    files
      .map(URL.init(fileURLWithPath:))
      .concurrentMap { ($0.deletingPathExtension().lastPathComponent, CGPDFDocument($0 as CFURL)!) }
      .flatMap { $0.1.pages.appendToAll(a: $0.0) }
      .concurrentMap { ($0.0, $0.1.render(scale: scale.cgfloat)!) }
      .forEach { (name: String, img: CGImage) in
        let url = URL(fileURLWithPath: out)
          .appendingPathComponent("\(name)\(suffix).png") as CFURL
        try! img.write(fileURL: url)
      }
  }
}

Main.main()
