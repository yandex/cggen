import CoreGraphics
import Foundation
import Testing

import Base
import CGGenRuntime
import SnapshotTesting

@Suite struct SVGRuntimeRenderingTests {
  @Test("SVG Runtime Rendering", arguments: SVGTestCase.smokeTestSubset)
  func svgRuntimeRendering(testCase: SVGTestCase) throws {
    let svgURL = svgSamplesPath
      .appendingPathComponent(testCase.rawValue)
      .appendingPathExtension("svg")

    let svgData = try Data(contentsOf: svgURL)

    // Render at 2x scale
    let runtimeImage = try CGImage.svg(
      svgData,
      scale: 2.0
    )

    // Compare against the same webkit-references used by bytecode tests
    SnapshotTesting.withSnapshotTesting(record: .never) {
      assertSnapshot(
        of: runtimeImage.redraw(with: CGColor.white),
        as: .cgImage(tolerance: testCase.tolerance),
        named: testCase.rawValue,
        file: svgTestsFilePath,
        testName: "webkit-references"
      )
    }
  }
}
