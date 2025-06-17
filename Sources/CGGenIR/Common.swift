import Foundation

struct GenericError: Swift.Error {
  var desc: String

  init(_ desc: String) {
    self.desc = desc
  }
}
