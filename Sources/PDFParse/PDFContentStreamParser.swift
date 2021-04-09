import Foundation

import Base

enum PDFContentStreamParser {
  static func parse(stream: CGPDFContentStreamRef) -> [PDFOperator] {
    var context = Context()
    let operatorTable = makeOperatorTable()
    let scanner = CGPDFScannerCreate(stream, operatorTable, &context)
    CGPDFScannerScan(scanner)
    CGPDFScannerRelease(scanner)
    CGPDFContentStreamRelease(stream)
    return context.operators
  }

  private class Context {
    var operators = [PDFOperator]()
  }

  private static func ctx(_ info: UnsafeMutableRawPointer?) -> Context {
    info!.load(as: Context.self)
  }

  private static func makeOperatorTable() -> CGPDFOperatorTableRef {
    let operatorTableRef = CGPDFOperatorTableCreate()!
    typealias Parser = PDFContentStreamParser
    CGPDFOperatorTableSetCallback(operatorTableRef, "b") { _, info in
      Parser.ctx(info).operators.append(.closeFillStrokePathWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "B") { _, info in
      Parser.ctx(info).operators.append(.fillStrokePathWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "b*") { _, info in
      Parser.ctx(info).operators.append(.closeFillStrokePathEvenOdd)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "B*") { _, info in
      Parser.ctx(info).operators.append(.fillStrokePathEvenOdd)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BDC") { _, info in
      Parser.ctx(info).operators.append(.markedContentSequenceWithPListBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BI") { _, info in
      Parser.ctx(info).operators.append(.inlineImageBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BMC") { _, info in
      Parser.ctx(info).operators.append(.markedContentSequenceBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BT") { _, info in
      Parser.ctx(info).operators.append(.textObjectBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BX") { _, info in
      Parser.ctx(info).operators.append(.compatabilitySectionBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "c") { scanner, info in
      let c3 = scanner.popPoint()!
      let c2 = scanner.popPoint()!
      let c1 = scanner.popPoint()!
      Parser.ctx(info).operators.append(.curveTo(c1, c2, c3))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "cm") { scanner, info in
      let transform = scanner.popAffineTransform()!
      Parser.ctx(info).operators.append(.concatCTM(transform))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "CS") { scanner, _ in
      let name = scanner.popName()!
      // Parser.ctx(info).operators.append(.colorSpaceStroke(name))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "cs") { scanner, _ in
      let name = scanner.popName()!
      // Parser.ctx(info).operators.append(.colorSpaceNonstroke(name))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "d") { scanner, info in
      let phase = CGFloat(scanner.popInt()!)
      let lengths = scanner.popArray()!.map { CGFloat($0.realFromIntOrReal()!) }
      Parser.ctx(info).operators.append(.dash(phase, lengths))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "d0") { _, info in
      Parser.ctx(info).operators.append(.glyphWidthInType3Font)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "d1") { _, info in
      Parser.ctx(info).operators.append(.glyphWidthAndBoundingBoxInType3Font)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "Do") { scanner, info in
      let name = scanner.popName()!
      Parser.ctx(info).operators.append(.invokeXObject(name))
    }

    // TODO: DP, EI, EMC, ET, EX

    CGPDFOperatorTableSetCallback(operatorTableRef, "f") { _, info in
      Parser.ctx(info).operators.append(.fillWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "F") { _, info in
      Parser.ctx(info).operators.append(.fillWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "f*") { _, info in
      Parser.ctx(info).operators.append(.fillEvenOdd)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "G") { _, info in
      Parser.ctx(info).operators.append(.grayLevelStroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "g") { _, info in
      Parser.ctx(info).operators.append(.grayLevelNonstroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "gs") { scanner, info in
      let name = scanner.popName()!
      Parser.ctx(info).operators.append(.applyGState(name))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "h") { _, info in
      Parser.ctx(info).operators.append(.closeSubpath)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "i") { scanner, info in
      let tolerance = scanner.popNumber()!
      Parser.ctx(info).operators.append(.setFlatnessTolerance(tolerance))
    }

//    This prints a error. Should be investigated further
//    `ID' isn't an operator.
//    CGPDFOperatorTableSetCallback(operatorTableRef, "ID") { scanner, info in
//      Parser.ctx(info).operators.append(.inlineImageDataBegin)
//    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "j") { scanner, info in
      let style = scanner.popInt()!
      Parser.ctx(info).operators.append(.lineJoinStyle(style))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "J") { scanner, info in
      let style = scanner.popInt()!
      Parser.ctx(info).operators.append(.lineCapStyle(style))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "K") { _, info in
      Parser.ctx(info).operators.append(.cmykColorStroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "k") { _, info in
      Parser.ctx(info).operators.append(.cmykColorNonstroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "l") { scanner, info in
      let point = scanner.popPoint()!
      Parser.ctx(info).operators.append(.lineTo(point))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "m") { scanner, info in
      let point = scanner.popPoint()!
      Parser.ctx(info).operators.append(.moveTo(point))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "MP") { _, info in
      Parser.ctx(info).operators.append(.markedContentPointDefine)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "n") { _, info in
      Parser.ctx(info).operators.append(.endPath)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "q") { _, info in
      Parser.ctx(info).operators.append(.saveGState)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "Q") { _, info in
      Parser.ctx(info).operators.append(.restoreGState)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "re") { scanner, info in
      let rect = scanner.popRect()!
      Parser.ctx(info).operators.append(.appendRectangle(rect))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "RG") { scanner, info in
      let color = scanner.popColor()!
      Parser.ctx(info).operators.append(.rgbColorStroke(color))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "rg") { scanner, info in
      let color = scanner.popColor()!
      Parser.ctx(info).operators.append(.rgbColorNonstroke(color))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "ri") { scanner, info in
      let name = scanner.popName()!
      Parser.ctx(info).operators.append(.colorRenderingIntent(name))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "s") { _, info in
      Parser.ctx(info).operators.append(.closeAndStrokePath)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "S") { _, info in
      Parser.ctx(info).operators.append(.strokePath)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "SC") { scanner, info in
      let color = scanner.popColor()!
      Parser.ctx(info).operators.append(.colorStroke(color))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "sc") { scanner, info in
      let color = scanner.popColor()!
      Parser.ctx(info).operators.append(.rgbColorNonstroke(color))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "SCN") { scanner, info in
      let color = scanner.popColor()!
      Parser.ctx(info).operators.append(.colorStroke(color))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "scn") { scanner, info in
      let color = scanner.popColor()!
      Parser.ctx(info).operators.append(.rgbColorNonstroke(color))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "sh") { scanner, info in
      let name = scanner.popName()!
      Parser.ctx(info).operators.append(.shadingFill(name))
    }

    // TODO: text things: T*, Td, TD, Tf, Tj, TJ, Tm, Tr, Ts, Tw, Tz

    CGPDFOperatorTableSetCallback(operatorTableRef, "w") { scanner, info in
      let width = scanner.popNumber()!
      Parser.ctx(info).operators.append(.lineWidth(width))
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "W") { _, info in
      Parser.ctx(info).operators.append(.clipWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "W*") { _, info in
      Parser.ctx(info).operators.append(.clipEvenOdd)
    }
    // TODO: text things: ',"
    return operatorTableRef
  }
}

extension CGPDFScannerRef {
  fileprivate func popNumber() -> CGPDFReal? {
    var val: CGPDFReal = 0
    return CGPDFScannerPopNumber(self, &val) ? val : nil
  }

  fileprivate func popInt() -> CGPDFInteger? {
    var val: CGPDFInteger = 0
    return CGPDFScannerPopInteger(self, &val) ? val : nil
  }

  fileprivate func popArray() -> [PDFObject]? {
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

  fileprivate func popPoint() -> CGPoint? {
    guard let pair = popTwoNumbers() else { return nil }
    return CGPoint(x: pair.1, y: pair.0)
  }

  private func popSize() -> CGSize? {
    guard let pair = popTwoNumbers() else { return nil }
    return CGSize(width: pair.1, height: pair.0)
  }

  fileprivate func popRect() -> CGRect? {
    guard let size = popSize() else { return nil }
    guard let origin = popPoint() else { fatalError() }
    return CGRect(origin: origin, size: size)
  }

  fileprivate func popColor() -> PDFColor? {
    guard let blue = popNumber() else { return nil }
    guard let green = popNumber(), let red = popNumber() else { fatalError() }
    return PDFColor(red: red, green: green, blue: blue)
  }

  fileprivate func popName() -> String? {
    var pointer: UnsafePointer<Int8>?
    CGPDFScannerPopName(self, &pointer)
    guard let cString = pointer else { return nil }
    return String(cString: cString)
  }

  fileprivate func popAffineTransform() -> CGAffineTransform? {
    guard let f = popNumber() else { return nil }
    guard let e = popNumber(),
          let d = popNumber(),
          let c = popNumber(),
          let b = popNumber(),
          let a = popNumber() else { fatalError() }
    return CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
  }

  private func popObject() -> PDFObject? {
    var objP: CGPDFObjectRef?
    CGPDFScannerPopObject(self, &objP)
    guard let obj = objP else { return nil }
    return PDFObject(pdfObj: obj)
  }
}
