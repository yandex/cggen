import CoreGraphics
import Foundation

internal typealias PDFDictionary = [String: PDFObject]

internal enum PDFObject {
  case null
  case boolean(CGPDFBoolean)
  case integer(CGPDFInteger)
  case real(CGPDFReal)
  case name(String)
  case string(String)
  case array([PDFObject])
  case dictionary(PDFDictionary)
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
      self = .array(range.map { i -> PDFObject in
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
    @unknown default:
      fatalError("Unknown pdf object type \(type)")
    }
  }

  static func processDict(_ dict: CGPDFDictionaryRef) -> [String: PDFObject] {
    var result = NSMutableDictionary()
    withUnsafeMutablePointer(to: &result) { resultPtr in
      CGPDFDictionaryApplyFunction(dict, { key, obj, info in
        let result = info!.load(as: NSMutableDictionary.self)
        let key = String(cString: key)
        if key == "Parent" {
          result[key] = PDFObject.null
          return
        }
        result[key] = PDFObject(pdfObj: obj)
      }, resultPtr)
    }
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

  var intValue: Int? {
    if case let .integer(int) = self {
      return int
    }
    return nil
  }

  func integerArray() -> [Int]? {
    guard case let .array(a) = self else { return nil }
    return a.map { $0.intValue }.unwrap()
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

  var boolValue: Bool? {
    if case let .boolean(b) = self {
      return b != 0
    }
    return nil
  }

  var dictFromDictOrStream: [String: PDFObject]? {
    switch self {
    case let .dictionary(d):
      return d
    case let .stream(s):
      return s.dict
    default:
      return nil
    }
  }
}

extension CGRect {
  internal static func fromPDFArray(_ array: [PDFObject]) -> CGRect? {
    guard array.count == 4, let x = array[0].realFromIntOrReal(),
          let y = array[1].realFromIntOrReal(),
          let w = array[2].realFromIntOrReal(),
          let h = array[3].realFromIntOrReal() else { return nil }
    return self.init(x: x, y: y, width: w, height: h)
  }
}

extension CGAffineTransform {
  internal init?(pdfArray array: [PDFObject]) {
    guard array.count == 6,
          let a = array[0].realFromIntOrReal(),
          let b = array[1].realFromIntOrReal(),
          let c = array[2].realFromIntOrReal(),
          let d = array[3].realFromIntOrReal(),
          let e = array[4].realFromIntOrReal(),
          let f = array[5].realFromIntOrReal() else { return nil }
    self.init(a: a, b: b, c: c, d: d, tx: e, ty: f)
  }
}
