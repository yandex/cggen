// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import CoreGraphics
import Dispatch
import Foundation

infix operator !!
infix operator ^^

extension String {
  private var camelCaseComponents: [String] {
    let components = self.components(separatedBy: .uppercaseLetters)
    var currentPos = index(startIndex, offsetBy: components.first?.count ?? 0)
    var result: [String] = components.first.map { [$0] } ?? []
    for comp in components.dropFirst() {
      result.append(String(self[currentPos]) + comp)
      currentPos = index(currentPos, offsetBy: comp.count + 1)
    }
    return result
  }

  private var nameComponents: [String] {
    return components(separatedBy: CharacterSet(charactersIn: "_-: "))
      .flatMap { $0.camelCaseComponents }
  }

  public func capitalizedFirst() -> String {
    return prefix(1).uppercased() + dropFirst()
  }

  public var snakeCase: String {
    return nameComponents
      .map { $0.lowercased() }
      .joined(separator: "_")
  }

  public var lowerCamelCase: String {
    let comps = nameComponents
    return (comps.first ?? "").lowercased() + comps.dropFirst().map { $0.capitalized }.joined()
  }

  public var upperCamelCase: String {
    return nameComponents.map { $0.capitalized }.joined()
  }
}

extension Optional {
  public static func !!(v: Optional, e: Error) throws -> Wrapped {
    guard let unwrapped = v else { throw e }
    return unwrapped
  }

  public static func ^^ <T: Error>(v: Optional, e: T) -> Result<Wrapped, T> {
    guard let unwrapped = v else { return .failure(e) }
    return .success(unwrapped)
  }

  public func map<T>(_ kp: KeyPath<Wrapped, T>) -> T? {
    return map { $0[keyPath: kp] }
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
    return reduce([Element.Wrapped]?([])) { acc, e in
      acc.flatMap { a in e.optional.map { a + [$0] } }
    }
  }
}

extension Array {
  public func splitBy(subSize: Int) -> [ArraySlice<Element>] {
    return stride(from: 0, to: count, by: subSize).map { startIndex in
      let endIndex = startIndex.advanced(by: subSize)
      return self[startIndex..<endIndex]
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

  public mutating func modifyLast(_ modifier: (inout Element) -> Void) {
    guard var el = popLast() else { return }
    modifier(&el)
    append(el)
  }
}

extension Array where Element == String {
  public func appendFirstToLast(_ strings: [String], separator: String) -> [String] {
    let mid: String
    switch (last, strings.first) {
    case let (last?, nil):
      mid = last
    case let (nil, first?):
      mid = first
    case let (last?, first?):
      mid = last + separator + first
    case (nil, nil):
      return []
    }
    return dropLast() + [mid] + strings.dropFirst()
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

  public func insertSeparator(_ separator: Element) -> JoinedSequence<[[Self.Element]]> {
    return map { [$0] }.joined(separator: [separator])
  }
}

extension Collection {
  @inlinable
  public subscript(safe index: Index) -> Element? {
    startIndex <= index && endIndex > index ? self[index] : nil
  }
}

public func partial<A1, A2, T>(_ f: @escaping (A1, A2) throws -> T, arg2: A2) -> (A1) throws -> T {
  return { try f($0, arg2) }
}

@inlinable
public func identity<T>(_ t: T) -> T {
  return t
}

public func check(_ condition: Bool, _ error: Error) throws {
  if !condition {
    throw error
  }
}

public func zip<T, U>(_ t: T?, _ u: U?) -> (T, U)? {
  return t.flatMap { t in u.map { u in (t, u) } }
}

public func modified<T>(_ value: T, _ modifier: (inout T) -> Void) -> T {
  var copy = value
  modifier(&copy)
  return copy
}

public func waitCallbackOnMT(_ operation: (@escaping () -> Void) -> Void) {
  waitCallbackOnMT { completion in
    operation {
      completion(())
    }
  }
}

public func waitCallbackOnMT<T>(_ operation: (@escaping (T) -> Void) -> Void) -> T {
  let semaphore = DispatchSemaphore(value: 0)
  var result: T?
  operation {
    result = $0
    semaphore.signal()
  }

  RunLoop.current.spin {
    semaphore.wait(timeout: .now()) == .timedOut
  }

  return result!
}

extension RunLoop {
  public func spin(while condition: () -> Bool) {
    while condition() {
      run(until: .init())
    }
  }
}

public func apply<T>(_ f: () -> T) -> T {
  return f()
}

extension CaseIterable where Self: RawRepresentable, RawValue: Hashable {
  public static var rawValues: Set<AllCases.Element.RawValue> {
    return Set(allCases.map { $0.rawValue })
  }
}
