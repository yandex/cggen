// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct PDFXObject {
  static let unsupportedKeys: Set<String> =
    ["Ref", "Metadata", "PieceInfo", "StructParent", "StructParents", "OPI"]
  static let unsupportedSubtypes: Set<String> = [ "Image" ]
  let stream: PDFStream
  let resources: PDFResources
  let bbox: CGRect
  let group: Group?
  let matrix: CGAffineTransform?

  init?(obj: PDFObject) {
    guard case let .stream(stream) = obj,
      case let dict = stream.dict,
      case let .name(type)? = dict["Type"],
      case let .name(subtype)? = dict["Subtype"] else { return nil }
    precondition(type == "XObject")
    precondition(!PDFXObject.unsupportedSubtypes.contains(subtype),
                 "XObject with subtype \(subtype) is not supported")
    precondition(subtype == "Form",
                 "XObject with subtype \(subtype) is not implemnted (yet?)")
    guard case let .array(bboxArray)? = dict["BBox"],
      let resourcesDict = dict["Resources"],
      let resources = PDFResources(obj: resourcesDict),
      let bbox = CGRect.fromPDFArray(bboxArray) else { return nil }

    let group: Group?
    if case let .dictionary(groupDict)? = stream.dict["Group"] {
      group = Group(dict: groupDict)!
    } else {
      group = nil
    }
    let matrix: CGAffineTransform?
    if case let .array(matrixArray)? = stream.dict["Matrix"] {
      matrix = CGAffineTransform(pdfArray: matrixArray)
    } else {
      matrix = nil
    }

    let illegalKeys =
      Set(dict.keys).intersection(PDFXObject.unsupportedKeys)
    precondition(illegalKeys.isEmpty, "\(illegalKeys) are not supported")

    self.stream = stream
    self.resources = resources
    self.bbox = bbox
    self.group = group
    self.matrix = matrix
  }

  struct Group {
    let colorSpace: PDFObject?
    let isolated: Bool?
    let knockout: Bool?

    init?(dict: [String: PDFObject]) {
      guard case let .name(subtype)? = dict["S"]
      else { return nil }
      precondition(subtype == "Transparency")
      colorSpace = dict["CS"]
      isolated = dict["I"]?.boolValue
      knockout = dict["K"]?.boolValue
    }
  }
}

extension PDFXObject: CustomStringConvertible {
  var description: String {
    return """
    
    - resources: \(resources)
    - bbox: \(bbox)
    - group: \(String(describing: group))
    - matrix: \(String(describing: matrix))
    """
  }
}
