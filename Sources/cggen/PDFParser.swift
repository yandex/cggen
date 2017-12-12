// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

struct PDFFunction {
  struct Point {
    let arg: CGFloat
    let value: [CGFloat]
  }

  let rangeDim: Int
  let domainDim: Int
  let range: [(CGFloat, CGFloat)]
  let domain: [(CGFloat, CGFloat)]
  let size: [Int]
  let length: Int
  let points: [Point]

  init?(obj: PDFObject) {
    guard case let .stream(dict, format, data) = obj,
      let rangeObj = dict["Range"],
      case let .array(rangeArray) = rangeObj,
      let rangeRaw = rangeArray.map({ $0.realFromIntOrReal() }).unwrap(),
      let sizeObj = dict["Size"],
      let size = sizeObj.integerArray(),
      let length = dict["Length"]?.integerVal(),
      let domainObj = dict["Domain"],
      case let .array(domainArray) = domainObj,
      let domainRaw = domainArray.map({ $0.realFromIntOrReal() }).unwrap(),
      let bitsPerSample = dict["BitsPerSample"]?.integerVal()
      else { return nil }
    precondition(format == .raw)

    let range = rangeRaw.splitBy(subSize: 2).map { ($0[0], $0[1]) }
    let rangeDim = range.count
    let domain = domainRaw.splitBy(subSize: 2).map { ($0[0], $0[1]) }
    let domainDim = domain.count
    precondition(domainDim == 1, "Only R1 -> RN supported")

    precondition(bitsPerSample == 8, "Only UInt8 supported")
    let samples = [UInt8](data).map { CGFloat($0) / CGFloat(UInt8.max) }
    let values = samples.splitBy(subSize: rangeDim)
    let points = (0 ..< size[0]).map { (s) -> Point in
      let start = domain[0].0
      let end = domain[0].1
      let step = (end - start) / CGFloat(size[0] - 1)
      let current = start + CGFloat(s) * step
      return Point(arg: current, value: values[s])
    }.removeIntermediates()

    self.range = range
    self.rangeDim = rangeDim
    self.domain = domain
    self.domainDim = domainDim
    self.size = size
    self.length = length
    self.points = points
  }
}

extension PDFFunction.Point: LinearInterpolatable {
  typealias AbscissaType = CGFloat
  var abscissa: CGFloat { return arg }
  func near(_ other: PDFFunction.Point) -> Bool {
    let squareDistance = zip(value, other.value)
      .reduce(0) { (acc, pair) -> CGFloat in
        let d = pair.0 - pair.1
        return acc + d * d
    }
    return squareDistance < 0.001
  }
  static func linearInterpolate(from lhs: PDFFunction.Point,
                                to rhs: PDFFunction.Point,
                                at x: CGFloat) -> PDFFunction.Point {
    precondition(lhs.value.count == rhs.value.count)
    let outN = lhs.value.count
    let out = (0 ..< outN).map { (i) -> CGFloat in
      let x1 = lhs.arg
      let x2 = rhs.arg
      let y1 = lhs.value[i]
      let y2 = rhs.value[i]
      let k =  (y1 - y2) / (x1 - x2)
      let b = y1 - k * x1
      return k * x + b
    }
    return PDFFunction.Point(arg: x, value: out)
  }
}

struct PDFShading {
  enum ShadingType: Int  {
    case functionBased = 1
    case axial
    case radial
    case freeFormGouraudShadedTriangleMeshes
    case latticeFormGouraudShadedTriangleMeshes
    case coonsPatchMeshes
    case tensorProductPatchMeshes
  }
  let extend: (Bool, Bool)
  let colorSpace: PDFObject
  let type: ShadingType
  let domain: (CGFloat, CGFloat)
  let coords: (CGFloat, CGFloat, CGFloat, CGFloat)
  let function: PDFFunction

  init?(obj: PDFObject) {
    guard case let .dictionary(dict) = obj,
      // Extend
      let extendObj = dict["Extend"],
      case let .array(extendArray) = extendObj,
      case let .boolean(extendStart) = extendArray[0],
      case let .boolean(extendEnd) = extendArray[1],
      // Color space
      let colorSpace = dict["ColorSpace"],
      // Type
      let typeObj = dict["ShadingType"],
      case let .integer(typeInt) = typeObj,
      let type = ShadingType(rawValue: typeInt),
      // Domain
      let domainObj = dict["Domain"],
      case let .array(domainArray) = domainObj,
      let domainStart = domainArray[0].realFromIntOrReal(),
      let domainEnd = domainArray[1].realFromIntOrReal(),
      // Coordinates
      let coordsObj = dict["Coords"],
      case let .array(coordsArray) = coordsObj,
      let coordsX0 = coordsArray[0].realFromIntOrReal(),
      let coordsY0 = coordsArray[1].realFromIntOrReal(),
      let coordsX1 = coordsArray[2].realFromIntOrReal(),
      let coordsY1 = coordsArray[3].realFromIntOrReal(),
      // Function
      let functionObj = dict["Function"],
      let function = PDFFunction(obj: functionObj)
      else { return nil }

    precondition(type == .axial, "Only axial shading supported")

    self.extend = (extendStart != 0, extendEnd != 0)
    self.colorSpace = colorSpace
    self.type = type
    self.domain = (domainStart, domainEnd)
    self.coords = (coordsX0, coordsY0, coordsX1, coordsY1)
    self.function = function
  }

  func makeGradient() -> Gradient {
    let locationAndColors = function.points.map { (point) -> (CGFloat, RGBColor) in
      precondition(point.value.count == 3)
      let loc = point.arg
      let components = point.value
      let color = RGBColor(red: components[0],
                           green: components[1],
                           blue: components[2])
      return (loc, color)
    }
    var options: CGGradientDrawingOptions = []
    if extend.0 {
      options.insert(.drawsBeforeStartLocation)
    }
    if extend.1 {
      options.insert(.drawsAfterEndLocation)
    }
    let startPoint = CGPoint(x: coords.0, y: coords.1)
    let endPoint = CGPoint(x: coords.2, y: coords.3)
    return Gradient(locationAndColors: locationAndColors,
                    startPoint: startPoint,
                    endPoint: endPoint,
                    options: options)
  }
}

struct Resources {
  let shadings: [String:PDFShading]
  init?(obj: PDFObject) {
    guard case let .dictionary(dict) = obj
      else { return nil }
    let shadingDict = dict["Shading"]?.dictionaryVal() ?? [:]
    shadings = shadingDict.mapValues { PDFShading.init(obj: $0)! }
  }
}

enum PDFObject {
  case null
  case boolean(CGPDFBoolean)
  case integer(CGPDFInteger)
  case real(CGPDFReal)
  case name(String)
  case string(String)
  case array([PDFObject])
  case dictionary([String:PDFObject])
  case stream([String:PDFObject], CGPDFDataFormat, Data)
  
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
      var tempStream: CGPDFStreamRef? = nil;
      CGPDFObjectGetValue(obj, .stream, &tempStream)
      let stream = tempStream!
      var format: CGPDFDataFormat = .raw
      let data: NSData = CGPDFStreamCopyData(stream, &format)!
      let dict = CGPDFStreamGetDictionary(stream)!
      self = .stream(PDFObject.processDict(dict), format, data as Data)
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
    return a.map { return $0.integerVal() }.unwrap()
  }
  func dictionaryVal() -> [String:PDFObject]? {
    if case let .dictionary(d) = self {
      return d
    }
    return nil
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
  func popObject() -> PDFObject? {
    var objP: CGPDFObjectRef? = nil
    CGPDFScannerPopObject(self, &objP)
    guard let obj = objP else { return nil }
    return PDFObject(pdfObj: obj)
  }
}

class ParsingContext {
  var route: DrawRoute? = nil
}

func parse(pdfURL: CFURL) -> [DrawRoute] {
  guard let operatorTableRef = CGPDFOperatorTableCreate(),
      let pdfDoc = CGPDFDocument(pdfURL) else {
    fatalError("Could not open pdf file at: \(pdfURL)");
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

  CGPDFOperatorTableSetCallback(operatorTableRef, "gs") { (scanner, info) in
    callback(info: info, step: .parametersFromGraphicsState)
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

  CGPDFOperatorTableSetCallback(operatorTableRef, "rg") { (scanner, info) in
    callback(info: info, step: .nonStrokeColor(scanner.popColor()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "RG") { (scanner, info) in
    callback(info: info, step: .strokeColor(scanner.popColor()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "ri") { (scanner, info) in
    callback(info: info, step: .colorRenderingIntent)
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

  CGPDFOperatorTableSetCallback(operatorTableRef, "sh") { (scanner, info) in
    callback(info: info, step: .paintWithGradient(scanner.popName()!))
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

    let pageDictionary = PDFObject.processDict(page.dictionary!)
    let resources = Resources(obj: pageDictionary["Resources"]!)!

    let gradients = resources.shadings.mapValues { $0.makeGradient() }
    var route = DrawRoute(boundingRect: page.getBoxRect(.mediaBox),
                          gradients: gradients)

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
