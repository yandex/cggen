@_spi(WIP) @MainActor
public enum DrawingRenderCounter {
  public private(set) static var count: UInt64 = 0

  static func record() {
    count += 1
  }
}
