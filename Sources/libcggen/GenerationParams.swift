struct GenerationParams {
  enum Style: String {
    case plain
    case swiftFriendly = "swift-friendly"
  }

  let style: Style
  let prefix: String
  let module: String
}
