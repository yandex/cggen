import Foundation

enum Error: Swift.Error {
  case parsingError(file: String = #file, line: Int = #line)
  case unsupported(String, file: String = #file, line: Int = #line)
}
