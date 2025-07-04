import CoreGraphics

import CGGenCore

public struct PDFResources {
  public let shadings: [String: PDFShading]
  public let gStates: [String: PDFExtGState]
  public let xObjects: [String: PDFXObject]

  init(obj: PDFObject, parentStream: CGPDFContentStreamRef) throws {
    guard case let .dictionary(dict) = obj
    else { throw Error.parsingError() }
    let xobjFactory = partial(PDFXObject.init, arg2: parentStream)
    let shadingDict = dict["Shading"]?.dictionaryVal() ?? [:]
    let gStatesDict = dict["ExtGState"]?.dictionaryVal() ?? [:]
    let xObjectsDict = dict["XObject"]?.dictionaryVal() ?? [:]

    shadings = try shadingDict.mapValues { try PDFShading(obj: $0) }
    gStates = try gStatesDict
      .mapValues(partial(PDFExtGState.init, arg2: xobjFactory))
    xObjects = try xObjectsDict.mapValues(xobjFactory)
  }
}
