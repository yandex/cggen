// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public struct PDFResources {
  public let shadings: [String: PDFShading]
  public let gStates: [String: PDFExtGState]
  public let xObjects: [String: PDFXObject]

  internal init?(obj: PDFObject, parentStream: CGPDFContentStreamRef) {
    guard case let .dictionary(dict) = obj
    else { return nil }
    let shadingDict = dict["Shading"]?.dictionaryVal() ?? [:]
    let gStatesDict = dict["ExtGState"]?.dictionaryVal() ?? [:]
    let xObjectsDict = dict["XObject"]?.dictionaryVal() ?? [:]
    shadings = shadingDict.mapValues { try! PDFShading(obj: $0) }
    gStates = gStatesDict.mapValues { PDFExtGState(obj: $0)! }
    xObjects = xObjectsDict.mapValues {
      PDFXObject(obj: $0, parentStream: parentStream)!
    }
  }
}
