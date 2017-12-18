// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

struct Resources {
  let shadings: [String: PDFShading]
  let gStates: [String: PDFExtGState]
  init?(obj: PDFObject) {
    guard case let .dictionary(dict) = obj
    else { return nil }
    let shadingDict = dict["Shading"]?.dictionaryVal() ?? [:]
    let gStatesDict = dict["ExtGState"]?.dictionaryVal() ?? [:]
    shadings = shadingDict.mapValues { PDFShading(obj: $0)! }
    gStates = gStatesDict.mapValues { PDFExtGState(obj: $0)! }
  }
}

extension CGPDFDocument {
  var pages: [CGPDFPage] {
    return (1...numberOfPages).map { page(at: $0)! }
  }
}

private extension CGPDFScannerRef {
  func popNumber() -> CGPDFReal? {
    var val: CGPDFReal = 0
    return CGPDFScannerPopNumber(self, &val) ? val : nil
  }

  func popInt() -> CGPDFInteger? {
    var val: CGPDFInteger = 0
    return CGPDFScannerPopInteger(self, &val) ? val : nil
  }

  func popArray() -> [PDFObject]? {
    var pointer: CGPDFArrayRef?
    CGPDFScannerPopArray(self, &pointer)
    guard let array = pointer else { return nil }
    return (0..<CGPDFArrayGetCount(array)).map { i in
      var objPtr: CGPDFObjectRef?
      CGPDFArrayGetObject(array, i, &objPtr)
      return PDFObject(pdfObj: objPtr!)
    }
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
    var pointer: UnsafePointer<Int8>?
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
    var objP: CGPDFObjectRef?
    CGPDFScannerPopObject(self, &objP)
    guard let obj = objP else { return nil }
    return PDFObject(pdfObj: obj)
  }
}

enum PDFParser {
  private class ParsingContext {
    var route: DrawRoute
    let resources: Resources

    var strokeAlpha: CGFloat = 1
    var fillAlpha: CGFloat = 1

    var strokeRGBColor: RGBColor?
    var fillRGBColor: RGBColor?

    var strokeColor: RGBAColor {
      guard let strokeRGBColor = strokeRGBColor else {
        fatalError("Stroke color should been set")
      }
      return RGBAColor.rgb(strokeRGBColor, alpha: strokeAlpha)
    }

    var fillColor: RGBAColor {
      guard let fillRGBColor = fillRGBColor else {
        fatalError("Fill color should been set")
      }
      return RGBAColor.rgb(fillRGBColor, alpha: fillAlpha)
    }

    init(route: DrawRoute, resources: Resources) {
      self.route = route
      self.resources = resources
    }
  }

  static func parse(pdfURL: CFURL) -> [DrawRoute] {
    guard let pdfDoc = CGPDFDocument(pdfURL) else {
      fatalError("Could not open pdf file at: \(pdfURL)")
    }
    let operatorTable = makeOperatorTable()

    return pdfDoc.pages.map { page in
      let stream = CGPDFContentStreamCreateWithPage(page)

      let pageDictionary = PDFObject.processDict(page.dictionary!)
      let resources = Resources(obj: pageDictionary["Resources"]!)!

      let gradients = resources.shadings.mapValues { $0.makeGradient() }
      let route = DrawRoute(boundingRect: page.getBoxRect(.mediaBox),
                            gradients: gradients)
      var context = ParsingContext(route: route, resources: resources)

      let scanner = CGPDFScannerCreate(stream, operatorTable, &context)
      CGPDFScannerScan(scanner)

      CGPDFScannerRelease(scanner)
      CGPDFContentStreamRelease(stream)
      return context.route
    }
  }

  private static func callback(info: UnsafeMutableRawPointer?,
                               step: DrawStep) {
    callback(context: info!.load(as: ParsingContext.self), step: step)
  }

  private static func callback(context: ParsingContext, step: DrawStep) {
    let n = context.route.push(step: step)
    log("\(n): \(step)")
  }

  private static func getContext(_ info: UnsafeMutableRawPointer?) -> ParsingContext {
    return info!.load(as: ParsingContext.self)
  }

  private static func makeOperatorTable() -> CGPDFOperatorTableRef {
    let operatorTableRef = CGPDFOperatorTableCreate()!
    CGPDFOperatorTableSetCallback(operatorTableRef, "b") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "B") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "b*") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "B*") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BDC") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BT") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BX") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "c") { scanner, info in
      let c3 = scanner.popPoint()!
      let c2 = scanner.popPoint()!
      let c1 = scanner.popPoint()!
      PDFParser.callback(info: info, step: .curve(c1, c2, c3))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "cm") { scanner, info in
      PDFParser.callback(info: info, step: .concatCTM(scanner.popAffineTransform()!))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "CS") { _, info in
      PDFParser.callback(info: info, step: .strokeColorSpace)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "cs") { _, info in
      // TBD: Extract proper color space
      PDFParser.callback(info: info, step: .fillColorSpace)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "d") { scanner, info in
      let phase = CGFloat(scanner.popInt()!)
      let lengths = scanner.popArray()!.map { CGFloat($0.integerVal()!) }
      let pattern = DashPattern(phase: phase, lengths: lengths)
      PDFParser.callback(info: info, step: .dash(pattern))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "gs") { scanner, info in
      let context = info!.load(as: ParsingContext.self)
      let gsName = scanner.popName()!
      let extGState = context.resources.gStates[gsName]!
      extGState.commands.forEach({ cmd in
        switch cmd {
        case let .fillAlpha(a):
          context.fillAlpha = a
        case let .strokeAlpha(a):
          context.strokeAlpha = a
        }
      })
      log("push gstate: \(extGState)")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "q") { _, info in
      PDFParser.callback(info: info, step: .saveGState)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "Q") { _, info in
      PDFParser.callback(info: info, step: .restoreGState)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "l") { scanner, info in
      PDFParser.callback(info: info, step: .line(scanner.popPoint()!))
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "h") { _, info in
      PDFParser.callback(info: info, step: .closePath)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "n") { _, info in
      PDFParser.callback(info: info, step: .endPath)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "i") { scanner, info in
      PDFParser.callback(info: info, step: .flatness(scanner.popNumber()!))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "m") { scanner, info in
      PDFParser.callback(info: info, step: .moveTo(scanner.popPoint()!))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "re") { scanner, info in
      PDFParser.callback(info: info, step: .appendRectangle(scanner.popRect()!))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "rg") { scanner, info in
      PDFParser.getContext(info).fillRGBColor = scanner.popColor()!
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "RG") { scanner, info in
      PDFParser.getContext(info).strokeRGBColor = scanner.popColor()!
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "ri") { _, info in
      PDFParser.callback(info: info, step: .colorRenderingIntent)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "s") { _, _ in
      fatalError("not implemented")
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "S") { _, info in
      let context = PDFParser.getContext(info)
      PDFParser.callback(context: context,
                         step: .stroke(context.strokeColor))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "sc") { scanner, info in
      PDFParser.getContext(info).fillRGBColor = scanner.popColor()!
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "SC") { scanner, info in
      PDFParser.getContext(info).strokeRGBColor = scanner.popColor()!
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "sh") { scanner, info in
      PDFParser.callback(info: info, step: .paintWithGradient(scanner.popName()!))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "f") { _, info in
      let context = PDFParser.getContext(info)
      PDFParser.callback(context: context,
                         step: .fill(context.fillColor, .winding))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "w") { scanner, info in
      PDFParser.callback(info: info, step: .lineWidth(scanner.popNumber()!))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "W") { _, info in
      PDFParser.callback(info: info, step: .clip(.winding))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "W*") { _, info in
      PDFParser.callback(info: info, step: .clip(.evenOdd))
    }
    return operatorTableRef
  }
}
