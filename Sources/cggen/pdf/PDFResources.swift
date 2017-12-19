// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct PDFResources {
  let shadings: [String: PDFShading]
  let gStates: [String: PDFExtGState]
  let xObjects: [String: PDFXObject]
  init?(obj: PDFObject) {
    guard case let .dictionary(dict) = obj
    else { return nil }
    let shadingDict = dict["Shading"]?.dictionaryVal() ?? [:]
    let gStatesDict = dict["ExtGState"]?.dictionaryVal() ?? [:]
    let xObjectsDict = dict["XObject"]?.dictionaryVal() ?? [:]
    shadings = shadingDict.mapValues { PDFShading(obj: $0)! }
    gStates = gStatesDict.mapValues { PDFExtGState(obj: $0)! }
    xObjects = xObjectsDict.mapValues { PDFXObject(obj: $0)! }
    assert(xObjects.forAllValue { $0.subtype == "Form" },
           "Only Form implemented")
  }
}
