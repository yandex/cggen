// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import CoreGraphics
import Dispatch
import Foundation

infix operator !!
infix operator ^^
infix operator ?=

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

  @inlinable
  public static func HEX<T: BinaryInteger>(_ num: T) -> String {
    return .init(num, radix: 0x10, uppercase: true)
  }
}

extension Optional {
  public static func !!(
    v: Optional,
    e: @autoclosure () -> Error
  ) throws -> Wrapped {
    guard let unwrapped = v else { throw e() }
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

public func ?= <T>(v: inout T, val: T?) {
  if let val = val {
    v = val
  }
}

extension Sequence where Iterator.Element: OptionalType {
  public func unwrap() -> [Iterator.Element.Wrapped]? {
    return reduce([Element.Wrapped]?([])) { acc, e in
      acc.flatMap { a in e.optional.map { a + [$0] } }
    }
  }
}

public struct Splitted<Collection: Swift.Collection>: Swift.Collection {
  public func index(after i: Index) -> Index {
    return i.advanced(by: 1)
  }

  @inlinable
  public subscript(position: Int) -> Collection.SubSequence {
    _read {
      let start = collection
        .index(collection.startIndex, offsetBy: position * step)
      let end = collection.index(start, offsetBy: step)
      yield collection[start..<end]
    }
  }

  public typealias Index = Int
  public typealias Indicies = Range<Int>
  public typealias SubSequence = Slice<Splitted<Collection>>
  public typealias Element = Collection.SubSequence

  public var startIndex: Int { return 0 }
  public var endIndex: Int {
    precondition(step > 0)
    return collection.count / step
  }

  public var step: Int
  public var collection: Collection

  @inlinable
  public func makeIterator() -> Iterator {
    return .init(collection: collection, step: step)
  }

  public struct Iterator: IteratorProtocol {
    private let collection: Collection
    private let step: Int
    private var idx: Collection.Index

    public mutating func next() -> Element? {
      guard idx < collection.endIndex else {
        return nil
      }
      let current = idx
      collection.formIndex(&idx, offsetBy: step)
      return collection[current..<idx]
    }

    public init(collection: Collection, step: Int) {
      precondition(step > 0)
      self.collection = collection
      self.step = step
      idx = collection.startIndex
    }
  }

  @inlinable
  init(collection: Collection, step: Int) {
    precondition(step > 0)
    self.step = step
    self.collection = collection
  }
}

extension Collection where Index == Int {
  public func splitBy(subSize: Int) -> Splitted<Self> {
    return Splitted(collection: self, step: subSize)
  }
}

extension Array {
  public func appendToAll<T>(a: T) -> [(T, Element)] {
    return map { (a, $0) }
  }

  public func concurrentMap<T>(_ transform: (Element) throws -> T) throws -> [T] {
    var result = [T?](repeating: nil, count: count)
    let lock = NSLock()
    var barrier: Error?
    DispatchQueue.concurrentPerform(iterations: count) { i in
      guard lock.locked({ barrier == nil }) else { return }
      do {
        let val = try transform(self[i])
        lock.locked { result[i] = val }
      } catch {
        lock.locked { barrier = error }
      }
    }
    if let error = barrier {
      throw error
    }
    return result.map { $0! }
  }

  public func concurrentMap<T>(_ transform: (Element) -> T) -> [T] {
    var result = [T?](repeating: nil, count: count)
    let resultQueue = DispatchQueue(label: "result_queue")
    DispatchQueue.concurrentPerform(iterations: count) { i in
      let val = transform(self[i])
      resultQueue.async {
        result[i] = val
      }
    }
    return resultQueue.sync { result.map { $0! } }
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
    return startIndex <= index && endIndex > index ? self[index] : nil
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

extension NSLock {
  func locked<T>(_ block: () -> T) -> T {
    lock()
    defer { unlock() }
    return block()
  }
}

@inlinable
public func hex<T>(_ bytes: T) -> String {
  return withUnsafeBytes(of: bytes) {
    $0.map(String.HEX).joined()
  }
}
