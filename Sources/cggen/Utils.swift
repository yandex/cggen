// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

struct Logger {
  static var shared = Logger()
  private var level: Bool?
  mutating func setLevel(level: Bool) {
    self.level = level
  }

  func log(_ s: String) {
    guard let level = level else { fatalError("log level must be set") }
    if level {
      print(s)
    }
  }
}

func log(_ s: String) {
  Logger.shared.log(s)
}
