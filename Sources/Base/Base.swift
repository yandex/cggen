import CoreGraphics
import Dispatch
import Foundation

precedencegroup Application {
  associativity: left
}

precedencegroup ForwardComposition {
  associativity: left
  higherThan: Application
}

infix operator !!
infix operator ^^
infix operator ?=
infix operator >>>: ForwardComposition
infix operator |>: Application
prefix operator ^

extension String {
  private var camelCaseComponents: [String] {
    let components = components(separatedBy: .uppercaseLetters)
    var currentPos = index(startIndex, offsetBy: components.first?.count ?? 0)
    var result: [String] = components.first.map { [$0] } ?? []
    for comp in components.dropFirst() {
      result.append(String(self[currentPos]) + comp)
      currentPos = index(currentPos, offsetBy: comp.count + 1)
    }
    return result
  }

  private var nameComponents: [String] {
    components(separatedBy: CharacterSet(charactersIn: "_-: "))
      .flatMap(\.camelCaseComponents)
  }

  public func capitalizedFirst() -> String {
    prefix(1).uppercased() + dropFirst()
  }

  public var snakeCase: String {
    nameComponents
      .map { $0.lowercased() }
      .joined(separator: "_")
  }

  public var lowerCamelCase: String {
    let comps = nameComponents
    return (comps.first ?? "").lowercased() + comps.dropFirst()
      .map(\.capitalized).joined()
  }

  public var upperCamelCase: String {
    nameComponents.map(\.capitalized).joined()
  }

  @inlinable
  public static func HEX(_ num: some BinaryInteger) -> String {
    .init(num, radix: 0x10, uppercase: true)
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
}

public protocol OptionalType {
  associatedtype Wrapped
  var optional: Wrapped? { get }
}

extension Optional: OptionalType {
  public var optional: Wrapped? { self }
}

public func ?= <T>(v: inout T, val: T?) {
  if let val {
    v = val
  }
}

extension Sequence where Iterator.Element: OptionalType {
  public func unwrap() -> [Iterator.Element.Wrapped]? {
    reduce([Element.Wrapped]?([])) { acc, e in
      acc.flatMap { a in e.optional.map { a + [$0] } }
    }
  }
}

public struct Splitted<Collection: Swift.Collection>: Swift.Collection {
  public func index(after i: Index) -> Index {
    i.advanced(by: 1)
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

  public var startIndex: Int { 0 }
  public var endIndex: Int {
    precondition(step > 0)
    return collection.count / step
  }

  public var step: Int
  public var collection: Collection

  @inlinable
  public func makeIterator() -> Iterator {
    .init(collection: collection, step: step)
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
    Splitted(collection: self, step: subSize)
  }
}

struct UncheckedSendable<T>: @unchecked Sendable {
  var value: T
}

extension Array {
  public func appendToAll<T>(a: T) -> [(T, Element)] {
    map { (a, $0) }
  }

  public func concurrentMap<T>(
    _ transform: @Sendable (Element) throws -> T
  ) throws -> [T] where Element: Sendable, T: Sendable {
    nonisolated(unsafe)
    var result = [T?](repeating: nil, count: count)
    let lock = NSLock()
    nonisolated(unsafe)
    var barrier: Error?
    DispatchQueue.concurrentPerform(iterations: count) { i in
      guard lock.withLock({ barrier == nil }) else { return }
      do {
        let val = try transform(self[i])
        lock.withLock { result[i] = val }
      } catch {
        lock.withLock { barrier = error }
      }
    }
    if let error = barrier {
      throw error
    }
    return result.map { $0! }
  }

  public func concurrentMap<T>(
    _ transform: @Sendable (Element) -> T
  ) -> [T] where Element: Sendable, T: Sendable {
    [T](unsafeUninitializedCapacity: count) { buffer, finalCount in
      finalCount = count
      let bufferAccess = NSLock()
      let uncheckedBuffer = UncheckedSendable(value: buffer)
      DispatchQueue.concurrentPerform(iterations: count) { i in
        let val = transform(self[i])
        bufferAccess.withLock {
          uncheckedBuffer.value.initializeElement(at: i, to: val)
        }
      }
    }
  }

  public mutating func modifyLast(_ modifier: (inout Element) -> Void) {
    guard var el = popLast() else { return }
    modifier(&el)
    append(el)
  }
}

extension [String] {
  public func appendFirstToLast(
    _ strings: [String],
    separator: String
  ) -> [String] {
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
  public func concurrentMap<T>(
    _ transform: @Sendable @escaping (Element) -> T
  ) -> [T] where Element: Sendable, T: Sendable {
    nonisolated(unsafe)
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

  public func insertSeparator(
    _ separator: Element
  ) -> JoinedSequence<[[Self.Element]]> {
    map { [$0] }.joined(separator: [separator])
  }
}

extension Collection {
  @inlinable
  public subscript(safe index: Index) -> Element? {
    startIndex <= index && endIndex > index ? self[index] : nil
  }

  @inlinable
  public var firstAndOnly: Element? {
    guard let first, count == 1 else {
      return nil
    }
    return first
  }
}

extension Result {
  @inlinable
  public var value: Success? {
    guard case let .success(s) = self else { return nil }
    return s
  }

  public var isSucceed: Bool {
    guard case .success = self else { return false }
    return true
  }

  @inlinable
  public init(optional: Success?, or error: @autoclosure () -> (Failure)) {
    switch optional {
    case let some?:
      self = .success(some)
    case nil:
      self = .failure(error())
    }
  }

  @inlinable
  public func takeAction(
    onSuccess: (Success) -> Void,
    onFailure: (Failure) -> Void
  ) {
    switch self {
    case let .success(val): onSuccess(val)
    case let .failure(err): onFailure(err)
    }
  }

  @inlinable
  public func onSuccess(_ action: () -> Void) {
    onSuccess { _ in action() }
  }

  @inlinable
  public func onSuccess(_ action: (Success) -> Void) {
    takeAction(onSuccess: action, onFailure: always(()))
  }

  @inlinable
  public func onFailure(_ action: () -> Void) {
    onFailure { _ in action() }
  }

  @inlinable
  public func onFailure(_ action: (Error) -> Void) {
    takeAction(onSuccess: always(()), onFailure: action)
  }
}

public func partial<A1, A2, T>(
  _ f: @escaping (A1, A2) throws -> T,
  arg2: A2
) -> (A1) throws -> T {
  { try f($0, arg2) }
}

@inlinable @Sendable
public func always<T, U>(_ value: T) -> @Sendable (U) -> T {
  unsafeBitCast(
    { (_: U) -> T in value },
    to: (@Sendable (U) -> T).self
  )
}

@inlinable
public func always<T, U1, U2>(_ value: T) -> @Sendable (U1, U2) -> T {
  unsafeBitCast(
    { (_: U1, _: U2) -> T in value },
    to: (@Sendable (U1, U2) -> T).self
  )
}

@inlinable
public func always<T, U>(_ value: T) -> @Sendable (inout U) -> T {
  unsafeBitCast(
    { (_: inout U) -> T in value },
    to: (@Sendable (inout U) -> T).self
  )
}

@inlinable
public func absurd<T>(_: Never) -> T {}

@inlinable
public func absurd<T>(_: some Any, _: Never) -> T {}

@inlinable
public func >>> <A, B, C>(
  lhs: @escaping (A) -> B,
  rhs: @escaping (B) -> C
) -> (A) -> C {
  { rhs(lhs($0)) }
}

@inlinable
public func |> <A, B>(
  lhs: A,
  rhs: (A) throws -> B
) rethrows -> B {
  try rhs(lhs)
}

public func check(_ condition: Bool, _ error: Error) throws {
  if !condition {
    throw error
  }
}

public func zip<T, U>(_ t: T?, _ u: U?) -> (T, U)? {
  t.flatMap { t in u.map { u in (t, u) } }
}

public func zipLongest<T, U>(
  _ t: T?, _ u: U?,
  fillFirst: @autoclosure () -> T,
  fillSecond: @autoclosure () -> U
) -> (T, U)? {
  guard t != nil || u != nil else { return nil }
  return (t ?? fillFirst(), u ?? fillSecond())
}

public func modified<T>(_ value: T, _ modifier: (inout T) -> Void) -> T {
  var copy = value
  modifier(&copy)
  return copy
}

extension KeyPath {
  @inlinable
  public var getter: @Sendable (Root) -> Value {
    unsafeBitCast(
      { (root: Root) -> Value in
        root[keyPath: self]
      },
      to: (@Sendable (Root) -> Value).self
    )
  }
}

extension WritableKeyPath {
  @inlinable
  public var setter: @Sendable (inout Root, Value) -> Void {
    unsafeBitCast(
      { (root: inout Root, value: Value) in
        root[keyPath: self] = value
      },
      to: (@Sendable (inout Root, Value) -> Void).self
    )
  }
}

public func waitCallbackOnMT(_ operation: (@escaping () -> Void) -> Void) {
  waitCallbackOnMT { completion in
    operation {
      completion(())
    }
  }
}

public func waitCallbackOnMT<T>(
  _ operation: (@escaping (T) -> Void) -> Void
) -> T {
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
  f()
}

extension CaseIterable where Self: RawRepresentable, RawValue: Hashable {
  public static var rawValues: Set<AllCases.Element.RawValue> {
    Set(allCases.map(\.rawValue))
  }
}

@inlinable
public func hex(_ bytes: some Any) -> String {
  withUnsafeBytes(of: bytes) {
    $0.map(String.HEX).joined()
  }
}

@resultBuilder
public enum ArrayBuilder<Element> {
  public typealias Component = [Element]
  public typealias Expression = Element

  @inlinable
  public static func buildExpression(_ element: Expression) -> Component {
    [element]
  }

  @inlinable
  public static func buildExpression(_ element: Expression?) -> Component {
    element.map { [$0] } ?? []
  }

  @inlinable
  public static func buildOptional(_ component: Component?) -> Component {
    component ?? []
  }

  @inlinable
  public static func buildEither(first component: Component) -> Component {
    component
  }

  @inlinable
  public static func buildEither(second component: Component) -> Component {
    component
  }

  @inlinable
  public static func buildArray(_ components: [Component]) -> Component {
    Array(components.joined())
  }

  @inlinable
  public static func buildBlock(_ components: Component...) -> Component {
    Array(components.joined())
  }
}

extension Array {
  @inlinable
  public static func build(
    @ArrayBuilder<Element> _ builder: () -> [Element]
  ) -> [Element] {
    builder()
  }
}
