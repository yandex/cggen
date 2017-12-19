// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct PDFXObject {
  let stream: PDFStream
  let resources: PDFResources
  let subtype: String

  init?(obj: PDFObject) {
    guard case let .stream(stream) = obj,
      case let .name(type)? = stream.dict["Type"],
      case let .name(subtype)? = stream.dict["Subtype"],
      let resourcesDict = stream.dict["Resources"],
      let resources = PDFResources(obj: resourcesDict),
      type == "XObject"
    else { return nil }
    self.stream = stream
    self.resources = resources
    self.subtype = subtype
  }
}
