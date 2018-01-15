// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public struct PDFShading {
  public enum ShadingType: Int {
    case functionBased = 1
    case axial
    case radial
    case freeFormGouraudShadedTriangleMeshes
    case latticeFormGouraudShadedTriangleMeshes
    case coonsPatchMeshes
    case tensorProductPatchMeshes
  }

  public let extend: (Bool, Bool)
  let colorSpace: PDFObject
  public let type: ShadingType
  public let domain: (CGFloat, CGFloat)
  public let coords: (CGFloat, CGFloat, CGFloat, CGFloat)
  public let function: PDFFunction

  init?(obj: PDFObject) throws {
    guard case let .dictionary(dict) = obj,
      // Extend
      let extendObj = dict["Extend"],
      case let .array(extendArray) = extendObj,
      case let .boolean(extendStart) = extendArray[0],
      case let .boolean(extendEnd) = extendArray[1],
      // Color space
      let colorSpace = dict["ColorSpace"],
      // Type
      let typeObj = dict["ShadingType"],
      case let .integer(typeInt) = typeObj,
      let type = ShadingType(rawValue: typeInt),
      // Domain
      let domainObj = dict["Domain"],
      case let .array(domainArray) = domainObj,
      let domainStart = domainArray[0].realFromIntOrReal(),
      let domainEnd = domainArray[1].realFromIntOrReal(),
      // Coordinates
      let coordsObj = dict["Coords"],
      case let .array(coordsArray) = coordsObj,
      let coordsX0 = coordsArray[0].realFromIntOrReal(),
      let coordsY0 = coordsArray[1].realFromIntOrReal(),
      let coordsX1 = coordsArray[2].realFromIntOrReal(),
      let coordsY1 = coordsArray[3].realFromIntOrReal(),
      // Function
      let functionObj = dict["Function"]
    else { return nil }
    let function = try PDFFunction(obj: functionObj)

    precondition(type == .axial, "Only axial shading supported")

    extend = (extendStart != 0, extendEnd != 0)
    self.colorSpace = colorSpace
    self.type = type
    domain = (domainStart, domainEnd)
    coords = (coordsX0, coordsY0, coordsX1, coordsY1)
    self.function = function
  }
}
