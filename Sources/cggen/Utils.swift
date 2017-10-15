// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct Logger {
  static var shared = Logger()
  private var level: Bool? = nil
  mutating func setLevel(level: Bool) {
    self.level = level;
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

extension String {
  func capitalizedFirst() -> String {
    return prefix(1).uppercased() + dropFirst()
  }
  func snakeToCamelCase() -> String {
    return components(separatedBy: "_").map { $0.capitalizedFirst()}.joined()
  }
}

extension CGRect {
  var x: CGFloat {
    return origin.x
  }
  var y: CGFloat {
    return origin.y
  }
}
