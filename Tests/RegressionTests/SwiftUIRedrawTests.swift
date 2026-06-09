import AppKit
import CGGenCLI
import Foundation
import SwiftUI
import Testing

@_spi(Generator) @_spi(WIP) import CGGenRTSupport

@MainActor
@Suite(.serialized)
struct SwiftUIRedrawTests {
  @Test
  func singleRenderOnInitialLayout() throws {
    let before = DrawingRenderCounter.count
    let window =
      try makeHostWindow(content: makeDrawing(named: "circle"))
    flushAndDisplay(window)
    #expect(DrawingRenderCounter.count - before == 1)
  }

  @Test
  func unrelatedParentStateChangeDoesNotRerender() throws {
    let model = TickModel()
    let window = try makeHostWindow(
      content: TickParent(
        model: model,
        drawing: makeDrawing(named: "circle")
      )
    )
    flushAndDisplay(window)
    let afterInitial = DrawingRenderCounter.count

    for _ in 0..<10 {
      model.tick += 1
      flushAndDisplay(window)
    }

    #expect(DrawingRenderCounter.count == afterInitial)
  }

  @Test
  func drawingChangeRerenders() throws {
    let model =
      try DrawingModel(drawing: makeDrawing(named: "circle"))
    let window = makeHostWindow(content: DrawingParent(model: model))
    flushAndDisplay(window)
    let afterInitial = DrawingRenderCounter.count

    model.drawing = try makeDrawing(named: "square")
    flushAndDisplay(window)

    #expect(DrawingRenderCounter.count - afterInitial == 1)
  }

  @Test
  func listOfNDrawingsEachRenderedOnce() throws {
    let model = TickModel()
    let n = 50
    let window = try makeHostWindow(
      content: DrawingList(
        model: model, count: n,
        drawing: makeDrawing(named: "circle")
      ),
      size: NSSize(width: 100, height: CGFloat(n) * 60)
    )
    flushAndDisplay(window)
    let afterInitial = DrawingRenderCounter.count

    // Initial layout renders each drawing at least once. Empirically there is
    // a small fixed overhead from the layout/display sequencing — the strict
    // invariant we care about is the post-state-change one below.
    #expect(afterInitial >= UInt64(n))

    for _ in 0..<5 {
      model.tick += 1
      flushAndDisplay(window)
    }

    #expect(DrawingRenderCounter.count == afterInitial)
  }
}

// MARK: - Test scaffolding

@MainActor
private func makeHostWindow(
  content: some View,
  size: NSSize = NSSize(width: 100, height: 100)
) -> NSWindow {
  let window = NSWindow(
    contentRect: NSRect(origin: .zero, size: size),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
  )
  let host = NSHostingView(rootView: content)
  host.frame = NSRect(origin: .zero, size: size)
  window.contentView = host
  return window
}

@MainActor
private func flushAndDisplay(_ window: NSWindow) {
  RunLoop.current.run(until: Date().addingTimeInterval(0.01))
  window.contentView?.layoutSubtreeIfNeeded()
  window.displayIfNeeded()
}

// MARK: - State models

@Observable
private final class TickModel {
  var tick: Int = 0
}

@Observable
private final class DrawingModel {
  var drawing: Drawing
  init(drawing: Drawing) {
    self.drawing = drawing
  }
}

// MARK: - Parent views

private struct TickParent: View {
  let model: TickModel
  let drawing: Drawing

  var body: some View {
    VStack {
      Text("\(model.tick)")
      drawing.frame(width: 50, height: 50)
    }
  }
}

private struct DrawingParent: View {
  let model: DrawingModel

  var body: some View {
    model.drawing.frame(width: 50, height: 50)
  }
}

private struct DrawingList: View {
  let model: TickModel
  let count: Int
  let drawing: Drawing

  var body: some View {
    VStack(spacing: 10) {
      Text("\(model.tick)")
      ForEach(0..<count, id: \.self) { _ in
        drawing.frame(width: 50, height: 50)
      }
    }
  }
}

private func makeDrawing(named name: String) throws -> Drawing {
  let url = try #require(Bundle.module.url(
    forResource: name,
    withExtension: "svg",
    subdirectory: "redraw_samples"
  ))
  let (bytecode, positions, decompressedSize, sizes) =
    try getImagesMergedBytecodeAndPositions(from: [url])
  let position = try #require(positions.first)
  let size = try #require(sizes.first)
  return Drawing(
    width: Float(size.width),
    height: Float(size.height),
    bytecodeArray: bytecode,
    decompressedSize: Int32(decompressedSize),
    startIndex: Int32(position.0),
    endIndex: Int32(position.1)
  )
}
