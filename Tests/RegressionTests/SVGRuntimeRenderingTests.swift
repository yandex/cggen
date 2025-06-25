import CoreGraphics
import Foundation
import Testing
import XCTest

import Base
import CGGenRuntime
import SnapshotTesting

@Suite struct SVGRuntimeRenderingTests {
  @Test("SVG Runtime Rendering", arguments: runtimeTestCases)
  func svgRuntimeRendering(testCase: SVGTestCase) throws {
    let svgURL = svgSamplesPath
      .appendingPathComponent(testCase.rawValue)
      .appendingPathExtension("svg")

    let svgData = try Data(contentsOf: svgURL)

    // Render using CGGenRuntime with same size/scale as webkit tests
    let runtimeImage = try CGImage.svg(
      svgData,
      size: testCase.size,
      scale: 2.0
    )

    // Compare against the same webkit-references used by bytecode tests
    SnapshotTesting.withSnapshotTesting(record: .never) {
      assertSnapshot(
        of: runtimeImage.redraw(with: .white),
        as: .cgImage(tolerance: testCase.tolerance),
        named: testCase.rawValue,
        file: svgTestsFilePath,
        testName: "webkit-references"
      )
    }
  }
}

// Test cases that are supported by runtime rendering
private let runtimeTestCases: [SVGTestCase] = [
  // Gradients
  .gradient,
  .gradient_radial,
  .gradient_with_alpha,
  .gradient_shape,
  .gradient_three_dots,
  .gradient_transform_linear,
  .gradient_transform_radial,

  // Shapes
  .shapes,
  .path_circle_commands,
  .path_relative_commands,
  .path_short_commands,
  .path_fill_rule,

  // Styles
  .alpha,
  .caps_joins,
  .dashes,
  .group_opacity,
  .fill,
  .lines,

  // Transforms
  .transforms,

  // Special cases
  .use_tag,
  .clip_path,
  .colornames,
  .nested_transparent_group,

  // Note: These test cases exist in the enum but weren't in the runtime tests:
  // .gradient_relative, .gradient_stroke, .gradient_fill_stroke_combinations,
  // .gradient_units, .gradient_absolute_start_end, .gradient_opacity,
  // .gradient_with_mask, .miter_limit, .simple_mask,
  // .use_referencing_not_in_defs,
  // .topmost_presentation_attributes, .path_move_to_commands,
  // .path_complex_curve,
  // .path_short_commands, .path_smooth_curve, .path_fill_rule_nonzero_default,
  // .path_fill_rule_gstate, .path_quadratic_bezier, .shadow_simple,
  // .shadow_colors, .shadow_blur_radius
]
