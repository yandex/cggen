// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public struct PDFXObject {
  private static let unsupportedKeys: Set<String> =
    ["Ref", "Metadata", "PieceInfo", "StructParent", "StructParents", "OPI"]
  private static let unsupportedSubtypes: Set<String> = ["Image"]

  public let operators: [PDFOperator]
  public let resources: PDFResources
  public let bbox: CGRect
  public let group: Group?
  public let matrix: CGAffineTransform?

  init?(obj: PDFObject, parentStream: CGPDFContentStreamRef) {
    guard case let .stream(stream) = obj,
      case let dict = stream.dict,
      case let .name(type)? = dict["Type"],
      case let .name(subtype)? = dict["Subtype"] else { return nil }
    precondition(type == "XObject")
    precondition(!PDFXObject.unsupportedSubtypes.contains(subtype),
                 "XObject with subtype \(subtype) is not supported")
    precondition(subtype == "Form",
                 "XObject with subtype \(subtype) is not implemented (yet?)")

    let contentStream = CGPDFContentStreamCreateWithStream(stream.raw,
                                                           stream.rawDict,
                                                           parentStream)

    guard case let .array(bboxArray)? = dict["BBox"],
      let resourcesDict = dict["Resources"],
      let resources = PDFResources(obj: resourcesDict, parentStream: contentStream),
      let bbox = CGRect.fromPDFArray(bboxArray) else { return nil }
    let operators = PDFContentStreamParser.parse(stream: contentStream)

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

    self.operators = operators
    self.resources = resources
    self.bbox = bbox
    self.group = group
    self.matrix = matrix
  }

  public struct Group {
    let colorSpace: PDFObject?
    public let isolated: Bool
    public let knockout: Bool

    init?(dict: [String: PDFObject]) {
      guard case let .name(subtype)? = dict["S"]
      else { return nil }
      precondition(subtype == "Transparency")
      colorSpace = dict["CS"]
      isolated = dict["I"]?.boolValue ?? false
      knockout = dict["K"]?.boolValue ?? false
    }
  }
}

extension PDFXObject: CustomStringConvertible {
  public var description: String {
    return """
    
    - resources: \(resources)
    - bbox: \(bbox)
    - group: \(String(describing: group))
    - matrix: \(String(describing: matrix))
    """
  }
}
