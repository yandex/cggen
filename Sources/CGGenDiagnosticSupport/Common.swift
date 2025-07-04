import Foundation

// Simple error type matching the one from tests
public struct Err: Swift.Error {
  public var description: String

  public init(_ desc: String) {
    description = desc
  }
}
