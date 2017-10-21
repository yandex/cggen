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

protocol OptionalType {
  associatedtype Wrapped
  var optional: Wrapped? { get }
}

extension Optional: OptionalType {
  var optional: Wrapped? { return self }
}

extension Sequence where Iterator.Element: OptionalType {
  func unwrap() -> [Iterator.Element.Wrapped]? {
    return reduce(Optional<[Element.Wrapped]>([])) { acc, e in
      acc.flatMap { a in e.optional.map { a + [$0] } }
    }
  }
}

extension Array {
  func splitBy(subSize: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: subSize).map { startIndex in
      let endIndex = startIndex.advanced(by: subSize)
      return Array(self[startIndex ..< endIndex])
    }
  }
}

protocol LinearInterpolatable {
  associatedtype AbscissaType
  var abscissa: AbscissaType { get }
  func near(_ other: Self) -> Bool
  static func linearInterpolate(from lhs: Self, to rhs: Self, at x: AbscissaType) -> Self
}

extension Array where Element: LinearInterpolatable {
  func removeIntermediates() -> [ Element ] {
    if count == 2 {
      return self
    }

    var result = [ self[0] ]
    var startIndex = 0
    for currentIndex in (1..<count - 1) {
      let ip = Element.linearInterpolate(from: self[startIndex], to: self[currentIndex + 1], at: self[currentIndex].abscissa)
      if !ip.near(self[currentIndex]) {
        result.append(self[currentIndex])
        startIndex = currentIndex
      }
    }
    result.append(last!)
    return result
  }
}
