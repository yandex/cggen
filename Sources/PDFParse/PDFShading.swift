import CoreGraphics

import Base

public struct PDFShading {
  public typealias Extend = (before: Bool, after: Bool)
  public typealias Domain = (t0: CGFloat, t1: CGFloat)
  private static let defaultExtend: Extend = (false, false)
  private static let defaultDomain: Domain = (t0: 0.0, t1: 1.0)

  public struct Axial {
    public let coords: (p0: CGPoint, p1: CGPoint)
    public let domain: Domain
    public let function: PDFFunction
    public let extend: Extend

    init(dict: PDFDictionary) throws {
      guard let coords = dict["Coords"]?.floatArray(),
            let functionObj = dict["Function"],
            coords.count == 4
      else { throw Error.parsingError }
      self.coords = (
        p0: CGPoint(x: coords[0], y: coords[1]),
        p1: CGPoint(x: coords[2], y: coords[3])
      )
      function = try PDFFunction(obj: functionObj)
      domain = try dict["Domain"]?.domain() ?? defaultDomain
      extend = try dict["Extend"]?.extend() ?? defaultExtend
      try check(
        domain == defaultDomain,
        Error.unsupported("shading domain \(domain)")
      )
    }
  }

  public struct Radial {
    public let coords: (p0: CGPoint, p1: CGPoint)
    public let startRadius: CGFloat
    public let endRadius: CGFloat
    public let domain: Domain
    public let function: PDFFunction
    public let extend: Extend

    init(dict: PDFDictionary) throws {
      guard let coords = dict["Coords"]?.floatArray(),
            let functionObj = dict["Function"],
            coords.count == 6
      else { throw Error.parsingError }
      self.coords = (
        p0: CGPoint(x: coords[0], y: coords[1]),
        p1: CGPoint(x: coords[3], y: coords[4])
      )
      startRadius = coords[2]
      endRadius = coords[5]
      function = try PDFFunction(obj: functionObj)
      extend = try dict["Extend"]?.extend() ?? defaultExtend
      domain = try dict["Domain"]?.domain() ?? defaultDomain
      try check(
        domain == defaultDomain,
        Error.unsupported("shading domain \(domain)")
      )
    }
  }

  public enum Kind {
    case axial(Axial)
    case radial(Radial)
  }

  let colorSpace: PDFObject
  public let kind: Kind

  init(obj: PDFObject) throws {
    guard case let .dictionary(dict) = obj,
          case let .integer(typeInt)? = dict["ShadingType"],
          let type = ShadingType(rawValue: typeInt),
          let colorSpace = dict["ColorSpace"]
    else { throw Error.parsingError }

    self.colorSpace = colorSpace
    switch type {
    case .axial:
      let axial = try Axial(dict: dict)
      kind = .axial(axial)
    case .radial:
      let radial = try Radial(dict: dict)
      kind = .radial(radial)
    case .functionBased,
         .freeFormGouraudShadedTriangleMeshes,
         .latticeFormGouraudShadedTriangleMeshes,
         .coonsPatchMeshes,
         .tensorProductPatchMeshes:
      throw Error.unsupported("shading type \(type)")
    }
  }
}

public enum ShadingType: Int {
  case functionBased = 1
  case axial
  case radial
  case freeFormGouraudShadedTriangleMeshes
  case latticeFormGouraudShadedTriangleMeshes
  case coonsPatchMeshes
  case tensorProductPatchMeshes
}

extension PDFObject {
  fileprivate func extend() throws -> PDFShading.Extend {
    guard case let .array(array) = self,
          array.count == 2,
          case let .boolean(before) = array[0],
          case let .boolean(after) = array[1]
    else { throw Error.parsingError }
    return (before: before != 0, after: after != 0)
  }

  fileprivate func domain() throws -> PDFShading.Domain {
    guard let array = floatArray(),
          array.count == 2 else { throw Error.parsingError }
    return (array[0], array[1])
  }

  fileprivate func floatArray() -> [CGFloat]? {
    guard case let .array(array) = self,
          let a = array.map({ $0.realFromIntOrReal() }).unwrap()
    else { return nil }
    return a
  }

  private func boolArray() -> [Bool]? {
    guard case let .array(array) = self,
          let a = array.map({ $0.boolValue }).unwrap()
    else { return nil }
    return a
  }
}
