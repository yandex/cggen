import Foundation

public struct PDFSoftMask {
  public enum SubType: String {
    case alpha = "Alpha"
    case luminosity = "Luminosity"

    init(obj: PDFObject) throws {
      guard let name = obj.nameVal(),
            let value = SubType(rawValue: name) else {
        throw Error.parsingError
      }
      self = value
    }
  }

  let subType: SubType
  let transparencyGroup: PDFXObject

  init(obj: PDFObject, xobjFactory: PDFXObject.Factory) throws {
    guard let dict = obj.dictionaryVal(),
          dict["Type"]?.nameVal() == "Mask",
          let subType = try dict["S"].map(SubType.init),
          let transparencyGroup = try dict["G"].map(xobjFactory)
    else {
      throw Error.parsingError
    }
    self.subType = subType
    self.transparencyGroup = transparencyGroup
  }
}

public enum PDFGStateCommand {
  case fillAlpha(CGFloat)
  case strokeAlpha(CGFloat)
  case blendMode(String)
  case sMask(PDFSoftMask)
}

public struct PDFExtGState {
  public let commands: [PDFGStateCommand]
  init(obj: PDFObject, xobjFactory: PDFXObject.Factory) throws {
    guard let dict = obj.dictionaryVal() else { throw Error.parsingError }
    commands = try dict.compactMap { (arg) -> PDFGStateCommand? in
      let (key, val) = arg
      switch key {
      case "Type":
        guard val.nameVal() == "ExtGState" else { throw Error.parsingError }
        return nil
      case "ca":
        let alpha = val.realFromIntOrReal()!
        return .fillAlpha(alpha)
      case "CA":
        let alpha = val.realFromIntOrReal()!
        return .strokeAlpha(alpha)
      case "BM":
        let name = val.nameVal()!
        return .blendMode(name)
      case "SMask":
        let sMask = try PDFSoftMask(obj: val, xobjFactory: xobjFactory)
        return .sMask(sMask)
      default:
        throw Error.unsupported("graphical state command - '\(key)'")
      }
    }
  }
}
