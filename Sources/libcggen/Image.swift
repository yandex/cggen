import PDFParse

public struct Image {
  let name: String
  let route: DrawRoute

  public init(name: String, route: DrawRoute) {
    self.name = name
    self.route = route
  }
}
