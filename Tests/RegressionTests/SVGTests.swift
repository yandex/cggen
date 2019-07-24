import XCTest
import libcggen

class SVGTest: XCTestCase {
  let fm = FileManager.default

  @objc func testFoo() throws {
    let samplesPath = getCurentFilePath().appendingPathComponent("svg_samples")
    let svgs = try fm
      .contentsOfDirectory(at: samplesPath)
      .filter { $0.lastPathComponent.hasSuffix(".svg") }
    XCTAssert(svgs.count > 0)
  }
}

func getCurentFilePath(_ file: StaticString = #file) -> URL {
  return URL(fileURLWithPath: file.description, isDirectory: false)
    .deletingLastPathComponent()
}


extension FileManager {
  func contentsOfDirectory(at url: URL) throws -> [URL] {
    return try contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: nil,
      options: [])
  }
}
