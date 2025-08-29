import os.log

public struct Logger {
  public nonisolated(unsafe) static var shared = Logger()
  private var level: Bool?
  public mutating func setLevel(level: Bool) {
    self.level = level
  }

  func log(_ s: String) {
    guard let level else { fatalError("log level must be set") }
    if level {
      print(s)
    }
  }
}

public func log(_ s: String) {
  Logger.shared.log(s)
}

extension OSLog {
  @usableFromInline
  class Guard {
    var expectDealloc = false
    var reentranceGuard = true

    @usableFromInline
    init() {}

    @usableFromInline
    func enter() {
      precondition(reentranceGuard)
      reentranceGuard = false
      expectDealloc = true
    }

    deinit {
      precondition(expectDealloc)
    }
  }

  @inlinable
  public func signpost(_ desc: StaticString) -> () -> Void {
    let g = Guard()
    os_signpost(.begin, log: self, name: desc)
    return {
      os_signpost(.end, log: self, name: desc)
      g.enter()
    }
  }

  @inlinable
  public func signpostRegion<T>(
    _ desc: StaticString,
    _ region: () throws -> T
  ) rethrows -> T {
    os_signpost(.begin, log: self, name: desc)
    defer {
      os_signpost(.end, log: self, name: desc)
    }
    return try region()
  }
}
