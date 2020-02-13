import Foundation

public struct StopWatch {
  public struct Result: CustomStringConvertible {
    public let time: TimeInterval
    public var description: String {
      "\(time)"
    }
  }

  var started = Date()
  public init() {}

  public func lap() -> Result {
    Result(time: Date().timeIntervalSince(started))
  }

  public mutating func reset() -> Result {
    let prevStarted = started
    started = Date()
    return Result(time: Date().timeIntervalSince(prevStarted))
  }
}
