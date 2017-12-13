// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public struct StopWatch {
  public struct Result: CustomStringConvertible {
    public let time: TimeInterval
    public var description: String {
      return "\(time)"
    }
  }

  var started = Date()
  public init() {
  }

  public func lap() -> Result {
    return Result(time: Date().timeIntervalSince(started))
  }

  public mutating func reset() -> Result {
    let prevStarted = started
    started = Date()
    return Result(time: Date().timeIntervalSince(prevStarted))
  }
}
