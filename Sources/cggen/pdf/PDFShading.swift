// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct PDFShading {
  enum ShadingType: Int  {
    case functionBased = 1
    case axial
    case radial
    case freeFormGouraudShadedTriangleMeshes
    case latticeFormGouraudShadedTriangleMeshes
    case coonsPatchMeshes
    case tensorProductPatchMeshes
  }
  let extend: (Bool, Bool)
  let colorSpace: PDFObject
  let type: ShadingType
  let domain: (CGFloat, CGFloat)
  let coords: (CGFloat, CGFloat, CGFloat, CGFloat)
  let function: PDFFunction

  init?(obj: PDFObject) {
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
      let functionObj = dict["Function"],
      let function = PDFFunction(obj: functionObj)
      else { return nil }

    precondition(type == .axial, "Only axial shading supported")

    self.extend = (extendStart != 0, extendEnd != 0)
    self.colorSpace = colorSpace
    self.type = type
    self.domain = (domainStart, domainEnd)
    self.coords = (coordsX0, coordsY0, coordsX1, coordsY1)
    self.function = function
  }

  func makeGradient() -> Gradient {
    let locationAndColors = function.points.map { (point) -> (CGFloat, RGBAColor) in
      precondition(point.value.count == 3)
      let loc = point.arg
      let components = point.value
      let color = RGBAColor(red: components[0],
                            green: components[1],
                            blue: components[2],
                            alpha: 1)
      return (loc, color)
    }
    var options: CGGradientDrawingOptions = []
    if extend.0 {
      options.insert(.drawsBeforeStartLocation)
    }
    if extend.1 {
      options.insert(.drawsAfterEndLocation)
    }
    let startPoint = CGPoint(x: coords.0, y: coords.1)
    let endPoint = CGPoint(x: coords.2, y: coords.3)
    return Gradient(locationAndColors: locationAndColors,
                    startPoint: startPoint,
                    endPoint: endPoint,
                    options: options)
  }
}
