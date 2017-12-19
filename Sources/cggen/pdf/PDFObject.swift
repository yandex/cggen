// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

enum PDFObject {
  case null
  case boolean(CGPDFBoolean)
  case integer(CGPDFInteger)
  case real(CGPDFReal)
  case name(String)
  case string(String)
  case array([PDFObject])
  case dictionary([String: PDFObject])
  case stream(PDFStream)

  init(pdfObj obj: CGPDFObjectRef) {
    let type = CGPDFObjectGetType(obj)
    switch type {
    case .null:
      self = .null
    case .boolean:
      var bool: CGPDFBoolean = 0
      guard CGPDFObjectGetValue(obj, .boolean, &bool) else { fatalError() }
      self = .boolean(bool)
    case .integer:
      var integer: CGPDFInteger = 0
      guard CGPDFObjectGetValue(obj, .integer, &integer) else { fatalError() }
      self = .integer(integer)
    case .real:
      var real: CGPDFReal = 0
      guard CGPDFObjectGetValue(obj, .real, &real) else { fatalError() }
      self = .real(real)
    case .name:
      var tempCString: UnsafePointer<Int8>?
      CGPDFObjectGetValue(obj, .name, &tempCString)
      self = .name(String(cString: tempCString!))
    case .string:
      var tempString: CGPDFStringRef?
      CGPDFObjectGetValue(obj, .string, &tempString)
      let string: String = CGPDFStringCopyTextString(tempString!)! as String
      self = .string(string)
    case .array:
      var tempArray: CGPDFArrayRef?
      CGPDFObjectGetValue(obj, .array, &tempArray)
      let array = tempArray!
      let range = 0..<CGPDFArrayGetCount(array)
      self = .array(range.map { (i) -> PDFObject in
        var tempObj: CGPDFObjectRef?
        CGPDFArrayGetObject(array, i, &tempObj)
        let obj = tempObj!
        return PDFObject(pdfObj: obj)
      })
    case .dictionary:
      var tempDict: CGPDFDictionaryRef?
      CGPDFObjectGetValue(obj, .dictionary, &tempDict)
      self = .dictionary(PDFObject.processDict(tempDict!))
    case .stream:
      self = .stream(PDFStream(obj: obj)!)
    }
  }

  static func processDict(_ dict: CGPDFDictionaryRef) -> [String: PDFObject] {
    var result: NSMutableDictionary = NSMutableDictionary()
    CGPDFDictionaryApplyFunction(dict, { key, obj, info in
      let result = info!.load(as: NSMutableDictionary.self)
      let key = String(cString: key)
      if key == "Parent" {
        result[key] = PDFObject.null
        return
      }
      result[key] = PDFObject(pdfObj: obj)
    }, &result)
    return result as! [String: PDFObject]
  }

  func realFromIntOrReal() -> CGFloat? {
    if case let .real(real) = self {
      return real
    }
    if case let .integer(int) = self {
      return CGFloat(int)
    }
    return nil
  }

  func integerVal() -> Int? {
    if case let .integer(int) = self {
      return int
    }
    return nil
  }

  func integerArray() -> [Int]? {
    guard case let .array(a) = self else { return nil }
    return a.map { $0.integerVal() }.unwrap()
  }

  func dictionaryVal() -> [String: PDFObject]? {
    if case let .dictionary(d) = self {
      return d
    }
    return nil
  }

  func stringVal() -> String? {
    if case let .string(s) = self {
      return s
    }
    return nil
  }

  func nameVal() -> String? {
    if case let .name(s) = self {
      return s
    }
    return nil
  }
}
