import Foundation

import Base

enum PDFContentStreamParser {
  static func parse(stream: CGPDFContentStreamRef) throws -> [PDFOperator] {
    var context = Context()
    let operatorTable = makeOperatorTable()
    let scanner = CGPDFScannerCreate(stream, operatorTable, &context)
    CGPDFScannerScan(scanner)
    CGPDFScannerRelease(scanner)
    CGPDFContentStreamRelease(stream)
    return try context.operators.map { try $0.get() }
  }

  private class Context {
    private(set) var operators = [Result<PDFOperator, Error>]()

    func append(_ op: PDFOperator) {
      operators.append(.success(op))
    }

    func append(_ op: PDFOperator?, file: String = #file, line: Int = #line) {
      guard let op = op else {
        operators.append(.failure(.parsingError(file: file, line: line)))
        return
      }
      append(op)
    }

    func append(file: String = #file, line: Int = #line, _ factory: () -> PDFOperator?) {
      append(factory(), file: file, line: line)
    }
  }

  private static func ctx(_ info: UnsafeMutableRawPointer?) -> Context {
    info!.load(as: Context.self)
  }

  private static func makeOperatorTable() -> CGPDFOperatorTableRef {
    let operatorTableRef = CGPDFOperatorTableCreate()!
    typealias Parser = PDFContentStreamParser
    CGPDFOperatorTableSetCallback(operatorTableRef, "b") { _, info in
      Parser.ctx(info).append(.closeFillStrokePathWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "B") { _, info in
      Parser.ctx(info).append(.fillStrokePathWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "b*") { _, info in
      Parser.ctx(info).append(.closeFillStrokePathEvenOdd)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "B*") { _, info in
      Parser.ctx(info).append(.fillStrokePathEvenOdd)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BDC") { _, info in
      Parser.ctx(info).append(.markedContentSequenceWithPListBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BI") { _, info in
      Parser.ctx(info).append(.inlineImageBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BMC") { _, info in
      Parser.ctx(info).append(.markedContentSequenceBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BT") { _, info in
      Parser.ctx(info).append(.textObjectBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "BX") { _, info in
      Parser.ctx(info).append(.compatabilitySectionBegin)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "c") { scanner, info in
      Parser.ctx(info).append {
        guard let c3 = scanner.popPoint(),
              let c2 = scanner.popPoint(),
              let c1 = scanner.popPoint() else {
          return nil
        }
        return .curveTo(c1, c2, c3)
      }
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "cm") { scanner, info in
      Parser.ctx(info).append(
        scanner.popAffineTransform().map(PDFOperator.concatCTM)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "CS") { scanner, info in
      Parser.ctx(info).append(
        scanner.popName().map(PDFOperator.colorSpaceStroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "cs") { scanner, info in
      Parser.ctx(info).append(
        scanner.popName().map(PDFOperator.colorSpaceNonstroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "d") { scanner, info in
      Parser.ctx(info).append {
        guard let phase = scanner.popNumber(),
              let array = scanner.popArray(),
              let lengths = try? array.map({
                CGFloat(try $0.realFromIntOrReal() !! Error.parsingError())
              }) else {
          return nil
        }
        return .dash(phase, lengths)
      }
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "d0") { _, info in
      Parser.ctx(info).append(.glyphWidthInType3Font)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "d1") { _, info in
      Parser.ctx(info).append(.glyphWidthAndBoundingBoxInType3Font)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "Do") { scanner, info in
      Parser.ctx(info).append(
        scanner.popName().map(PDFOperator.invokeXObject)
      )
    }

    // TODO: DP, EI, EMC, ET, EX

    CGPDFOperatorTableSetCallback(operatorTableRef, "f") { _, info in
      Parser.ctx(info).append(.fillWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "F") { _, info in
      Parser.ctx(info).append(.fillWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "f*") { _, info in
      Parser.ctx(info).append(.fillEvenOdd)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "G") { _, info in
      Parser.ctx(info).append(.grayLevelStroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "g") { _, info in
      Parser.ctx(info).append(.grayLevelNonstroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "gs") { scanner, info in
      Parser.ctx(info).append(
        scanner.popName().map(PDFOperator.applyGState)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "h") { _, info in
      Parser.ctx(info).append(.closeSubpath)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "i") { scanner, info in
      Parser.ctx(info).append(
        scanner.popNumber().map(PDFOperator.setFlatnessTolerance)
      )
    }

//    This prints a error. Should be investigated further
//    `ID' isn't an operator.
//    CGPDFOperatorTableSetCallback(operatorTableRef, "ID") { scanner, info in
//      Parser.ctx(info).append(.inlineImageDataBegin)
//    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "j") { scanner, info in
      Parser.ctx(info).append(
        scanner.popInt().map(PDFOperator.lineJoinStyle)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "J") { scanner, info in
      Parser.ctx(info).append(
        scanner.popInt().map(PDFOperator.lineCapStyle)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "K") { _, info in
      Parser.ctx(info).append(.cmykColorStroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "k") { _, info in
      Parser.ctx(info).append(.cmykColorNonstroke)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "l") { scanner, info in
      Parser.ctx(info).append(
        scanner.popPoint().map(PDFOperator.lineTo)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "m") { scanner, info in
      Parser.ctx(info).append(
        scanner.popPoint().map(PDFOperator.moveTo)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "MP") { _, info in
      Parser.ctx(info).append(.markedContentPointDefine)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "n") { _, info in
      Parser.ctx(info).append(.endPath)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "q") { _, info in
      Parser.ctx(info).append(.saveGState)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "Q") { _, info in
      Parser.ctx(info).append(.restoreGState)
    }
    CGPDFOperatorTableSetCallback(operatorTableRef, "re") { scanner, info in
      Parser.ctx(info).append(
        scanner.popRect().map(PDFOperator.appendRectangle)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "RG") { scanner, info in
      Parser.ctx(info).append(
        scanner.popColor().map(PDFOperator.rgbColorStroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "rg") { scanner, info in
      Parser.ctx(info).append(
        scanner.popColor().map(PDFOperator.rgbColorNonstroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "ri") { scanner, info in
      Parser.ctx(info).append(
        scanner.popName().map(PDFOperator.colorRenderingIntent)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "s") { _, info in
      Parser.ctx(info).append(.closeAndStrokePath)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "S") { _, info in
      Parser.ctx(info).append(.strokePath)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "SC") { scanner, info in
      Parser.ctx(info).append(
        scanner.popColor().map(PDFOperator.colorStroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "sc") { scanner, info in
      Parser.ctx(info).append(
        scanner.popColor().map(PDFOperator.rgbColorNonstroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "SCN") { scanner, info in
      Parser.ctx(info).append(
        scanner.popColor().map(PDFOperator.colorStroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "scn") { scanner, info in
      Parser.ctx(info).append(
        scanner.popColor().map(PDFOperator.rgbColorNonstroke)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "sh") { scanner, info in
      Parser.ctx(info).append(
        scanner.popName().map(PDFOperator.shadingFill)
      )
    }

    // TODO: text things: T*, Td, TD, Tf, Tj, TJ, Tm, Tr, Ts, Tw, Tz

    CGPDFOperatorTableSetCallback(operatorTableRef, "w") { scanner, info in
      Parser.ctx(info).append(
        scanner.popNumber().map(PDFOperator.lineWidth)
      )
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "W") { _, info in
      Parser.ctx(info).append(.clipWinding)
    }

    CGPDFOperatorTableSetCallback(operatorTableRef, "W*") { _, info in
      Parser.ctx(info).append(.clipEvenOdd)
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
