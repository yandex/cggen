public struct GenerationParams {
  public enum Style: String {
    case plain
    case swiftFriendly = "swift-friendly"
  }

  public let style: Style
  let prefix: String
  let module: String

  public init(style: Style, prefix: String, module: String) {
    self.style = style
    self.prefix = prefix
    self.module = module
  }
}
