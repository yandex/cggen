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
  case dictionary([String:PDFObject])
  case stream([String:PDFObject])
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
      var tempCString: UnsafePointer<Int8>? = nil
      CGPDFObjectGetValue(obj, .name, &tempCString)
      self = .name(String(cString: tempCString!))
    case .string:
      var tempString: CGPDFStringRef? = nil
      CGPDFObjectGetValue(obj, .string, &tempString)
      let string: String = CGPDFStringCopyTextString(tempString!)! as String
      self = .string(string)
    case .array:
      var tempArray: CGPDFArrayRef? = nil;
      CGPDFObjectGetValue(obj, .array, &tempArray)
      let array = tempArray!
      let range = 0..<CGPDFArrayGetCount(array)
      self = .array(range.map { (i) -> PDFObject in
        var tempObj: CGPDFObjectRef? = nil
        CGPDFArrayGetObject(array, i, &tempObj)
        let obj = tempObj!
        return PDFObject(pdfObj: obj)
      })
    case .dictionary:
      var tempDict: CGPDFDictionaryRef? = nil;
      CGPDFObjectGetValue(obj, .dictionary, &tempDict)
      self = .dictionary(PDFObject.processDict(tempDict!))
    case .stream:
      var tempStream: CGPDFDictionaryRef? = nil;
      CGPDFObjectGetValue(obj, .stream, &tempStream)
      let stream = tempStream!
      let dict = CGPDFStreamGetDictionary(stream)!
      self = .stream(PDFObject.processDict(dict))
    }
  }

  static func processDict(_ dict: CGPDFDictionaryRef) -> [String : PDFObject] {
    var result: NSMutableDictionary = NSMutableDictionary()
    CGPDFDictionaryApplyFunction(dict, { (key, obj, info) in
      let result = info!.load(as: NSMutableDictionary.self)
      let key = String(cString: key)
      if key == "Parent" {
        result[key] = PDFObject.null
        return
      }
      result[key] = PDFObject(pdfObj: obj)
    }, &result)
    return result as! [String : PDFObject]
  }

  func fDictionary() -> [String:PDFObject] {
    guard case .dictionary(let d) = self else { fatalError() }
    return d
  }
}

extension CGPDFScannerRef {
  func popNumber() -> CGPDFReal? {
    var val : CGPDFReal = 0;
    return CGPDFScannerPopNumber(self, &val) ? val : nil
  }
  private func popTwoNumbers() -> (CGFloat, CGFloat)? {
    guard let a1 = popNumber() else {
      return nil
    }
    guard let a2 = popNumber() else {
      fatalError()
    }
    return (a1, a2)
  }
  func popPoint() -> CGPoint? {
    guard let pair = popTwoNumbers() else { return nil }
    return CGPoint(x: pair.1, y: pair.0)
  }
  func popSize() -> CGSize? {
    guard let pair = popTwoNumbers() else { return nil }
    return CGSize(width: pair.1, height: pair.0)
  }
  func popRect() -> CGRect? {
    guard let size = popSize() else { return nil }
    guard let origin = popPoint() else { fatalError() }
    return CGRect(origin: origin, size: size)
  }
  func popColor() -> RGBColor? {
    guard let blue = popNumber() else { return nil }
    guard let green = popNumber(), let red = popNumber() else { fatalError() }
    return RGBColor(red: red, green: green, blue: blue)
  }
  func popName() -> String? {
    var pointer: UnsafePointer<Int8>? = nil
    CGPDFScannerPopName(self, &pointer)
    guard let cString = pointer else { return nil }
    return String(cString: cString)
  }
  func popAffineTransform() -> CGAffineTransform? {
    guard let f = popNumber() else { return nil }
    guard let e = popNumber(),
      let d = popNumber(),
      let c = popNumber(),
      let b = popNumber(),
      let a = popNumber() else { fatalError() }
    return CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
  }
}

func parse(pdfURL: CFURL) -> [DrawRoute] {
  guard let operatorTableRef = CGPDFOperatorTableCreate(),
      let pdfDoc = CGPDFDocument(pdfURL) else {
    return [];
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "b") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "B") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "b*") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "B*") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "BDC") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "BT") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "BX") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "c") { (scanner, info) in
    let c3 = scanner.popPoint()!
    let c2 = scanner.popPoint()!
    let c1 = scanner.popPoint()!
    callback(info: info, step: .curve(c1, c2, c3))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "cm") { (scanner, info) in
    callback(info: info, step: .concatCTM(scanner.popAffineTransform()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "CS") { (scanner, info) in
    callback(info: info, step: .strokeColorSpace)
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "cs") { (scanner, info) in
    // TBD: Extract proper color space
    callback(info: info, step: .nonStrokeColorSpace)
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "d") { (scanner, info) in
    fatalError("not implemented")
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "q") { (scanner, info) in
    callback(info: info, step: .saveGState)
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "Q") { (scanner, info) in
    callback(info: info, step: .restoreGState)
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "l") { (scanner, info) in
    callback(info: info, step: .line(scanner.popPoint()!))
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "h") { (scanner, info) in
    callback(info: info, step: .closePath)
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "n") { (scanner, info) in
    callback(info: info, step: .endPath)
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "i") { (scanner, info) in
    callback(info: info, step: .flatness(scanner.popNumber()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "m") { (scanner, info) in
    callback(info: info, step: .moveTo(scanner.popPoint()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "re") { (scanner, info) in
    callback(info: info, step: .appendRectangle(scanner.popRect()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "s") { (scanner, info) in
    fatalError()
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "S") { (scanner, info) in
    callback(info: info, step: .stroke)
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "sc") { (scanner, info) in
    callback(info: info, step: .nonStrokeColor(scanner.popColor()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "SC") { (scanner, info) in
    callback(info: info, step: .strokeColor(scanner.popColor()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "f") { (scanner, info) in
    callback(info: info, step: .fill(.winding))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "w") { (scanner, info) in
    callback(info: info, step: .lineWidth(scanner.popNumber()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "W") { (scanner, info) in
    callback(info: info, step: .clip(.winding))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "W*") { (scanner, info) in
    callback(info: info, step: .clip(.evenOdd))
  }

  return (1...pdfDoc.numberOfPages).map { (pageNum) in
    let page = pdfDoc.page(at: pageNum)!

    let stream = CGPDFContentStreamCreateWithPage(page)
    var route = DrawRoute(boundingRect: page.getBoxRect(.mediaBox))

    let pageDictionary = PDFObject.processDict(page.dictionary!)
    guard case .dictionary(let resources) = pageDictionary["Resources"]! else {
      fatalError()
    }
    route.processResources(resources: resources)

    let scanner = CGPDFScannerCreate(stream, operatorTableRef, &route)
    CGPDFScannerScan(scanner)

    CGPDFScannerRelease(scanner)
    CGPDFContentStreamRelease(stream)
    return route
  }
}

func callback(info: UnsafeMutableRawPointer?, step : DrawStep) {
  let route = info!.load(as: DrawRoute.self)
  let n = route.push(step: step)
  cggen.log("\(n): \(step)")
  info!.storeBytes(of: route, as: DrawRoute.self)
}
