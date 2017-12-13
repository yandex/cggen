// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation
import CoreGraphics

extension String {
  public func capitalizedFirst() -> String {
    return prefix(1).uppercased() + dropFirst()
  }
  public func snakeToCamelCase() -> String {
    return components(separatedBy: "_").map { $0.capitalizedFirst()}.joined()
  }
}

public protocol OptionalType {
  associatedtype Wrapped
  var optional: Wrapped? { get }
}

extension Optional: OptionalType {
  public var optional: Wrapped? { return self }
}

extension Sequence where Iterator.Element: OptionalType {
  public func unwrap() -> [Iterator.Element.Wrapped]? {
    return reduce(Optional<[Element.Wrapped]>([])) { acc, e in
      acc.flatMap { a in e.optional.map { a + [$0] } }
    }
  }
}

extension Array {
  public func splitBy(subSize: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: subSize).map { startIndex in
      let endIndex = startIndex.advanced(by: subSize)
      return Array(self[startIndex ..< endIndex])
    }
  }
  public func appendToAll<T>(a: T) -> [(T, Element)] {
    return map { (a, $0) }
  }
}
