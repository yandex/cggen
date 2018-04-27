// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

public enum PDFGStateCommand {
  case fillAlpha(CGFloat)
  case strokeAlpha(CGFloat)
  case blendMode(String)
}

public struct PDFExtGState {
  public let commands: [PDFGStateCommand]
  init?(obj: PDFObject) {
    guard let dict = obj.dictionaryVal()
    else { return nil }
    commands = dict.flatMap { (arg) -> PDFGStateCommand? in
      let (key, val) = arg
      switch key {
      case "Type":
        precondition(val.nameVal() == "ExtGState",
                     "The type of PDF object must be ExtGState")
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
      default:
        fatalError("Unknown/unimplemented graphical state command – '\(key)'")
      }
    }
  }
}
