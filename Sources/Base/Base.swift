// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import CoreGraphics
import Dispatch
import Foundation

extension String {
  public func capitalizedFirst() -> String {
    return prefix(1).uppercased() + dropFirst()
  }

  public func snakeToCamelCase() -> String {
    return components(separatedBy: "_").map { $0.capitalizedFirst() }.joined()
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
      return Array(self[startIndex..<endIndex])
    }
  }

  public func appendToAll<T>(a: T) -> [(T, Element)] {
    return map { (a, $0) }
  }

  public func concurrentMap<T>(_ transform: (Element) -> T) -> [T] {
    var result = [T?](repeating: nil, count: count)
    let syncQueue = DispatchQueue(label: "sync_queue")
    DispatchQueue.concurrentPerform(iterations: count) { i in
      let val = transform(self[i])
      syncQueue.async {
        result[i] = val
      }
    }
    return syncQueue.sync {
      result.map { $0! }
    }
  }
}

extension Sequence {
  public func concurrentMap<T>(_ transform: @escaping (Element) -> T) -> [T] {
    var result = [T?]()
    let syncQueue = DispatchQueue(label: "sync_queue")
    let workQueue = DispatchQueue(label: "work_queue", attributes: .concurrent)
    for (i, e) in enumerated() {
      syncQueue.async {
        result.append(nil)
      }
      workQueue.async {
        let val = transform(e)
        syncQueue.sync {
          result[i] = val
        }
      }
    }
    return workQueue.sync(flags: .barrier) {
      syncQueue.sync {
        result.map { $0! }
      }
    }
  }

  public func forAll(_ predicate: (Element) -> Bool) -> Bool {
    for e in self {
      if !predicate(e) {
        return false
      }
    }
    return true
  }
}

extension Dictionary {
  public func forAllValue(_ predicate: (Dictionary.Value) -> Bool) -> Bool {
    return values.forAll(predicate)
  }
}
