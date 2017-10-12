//
//  PDFParser.swift
//  cggenPackageDescription
//
//  Created by Alfred Zien on 11/10/2017.
//

import Foundation

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
  func popColor() -> CGColor? {
    guard let blue = popNumber() else { return nil }
    guard let green = popNumber(), let red = popNumber() else { fatalError() }
    return CGColor(red: red, green: green, blue: blue, alpha: 1)
  }
}

func parse(scale: CGFloat) -> [CGImage] {
  let pdfURL = URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL

  // Create pdf document


  guard let operatorTableRef = CGPDFOperatorTableCreate(),
      let pdfDoc = CGPDFDocument(pdfURL) else {
    return [];
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "q") { (scanner, info) in
    callback(info: info, step: .saveGState)
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "Q") { (scanner, info) in
    callback(info: info, step: .restoreGState)
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "c") { (scanner, info) in
    let c3 = scanner.popPoint()!
    let c2 = scanner.popPoint()!
    let c1 = scanner.popPoint()!
    callback(info: info, step: .curve(c1, c2, c3))
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "l") { (scanner, info) in
    callback(info: info, step: .line(scanner.popPoint()!))
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "h") { (scanner, info) in
    callback(info: info, step: .closePath)
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "W") { (scanner, info) in
    callback(info: info, step: .clip(.winding))
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "n") { (scanner, info) in
    callback(info: info, step: .endPath)
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "i") { (scanner, info) in
    callback(info: info, step: .flatness(scanner.popNumber()!))
  }
  CGPDFOperatorTableSetCallback(operatorTableRef, "cs") { (scanner, info) in
    // FIXME: Extract proper color space
    let cs = CGColorSpaceCreateDeviceRGB();
    callback(info: info, step: .nonStrokeColorSpace(cs))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "m") { (scanner, info) in
    callback(info: info, step: .moveTo(scanner.popPoint()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "W*") { (scanner, info) in
    callback(info: info, step: .clip(.evenOdd))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "re") { (scanner, info) in
    callback(info: info, step: .appendRectangle(scanner.popRect()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "sc") { (scanner, info) in
    callback(info: info, step: .nonStrokeColor(scanner.popColor()!))
  }

  CGPDFOperatorTableSetCallback(operatorTableRef, "f") { (scanner, info) in
    callback(info: info, step: .fill(.winding))
  }

  return (1...pdfDoc.numberOfPages).map { (pageNum) -> CGImage in
    let page = pdfDoc.page(at: pageNum)!
    let stream = CGPDFContentStreamCreateWithPage(page)
    print()
    var route = DrawRoute(boundingRect: page.getBoxRect(.mediaBox))
    let scanner = CGPDFScannerCreate(stream, operatorTableRef, &route)
    CGPDFScannerScan(scanner)

    CGPDFScannerRelease(scanner)
    CGPDFContentStreamRelease(stream)
    return route.draw(scale: scale)
  }
}

func callback(info: UnsafeMutableRawPointer?, step : DrawStep) {
  let route = info!.load(as: DrawRoute.self)
  let n = route.push(step: step)
  print("\(n) \(step)")
  info!.storeBytes(of: route, as: DrawRoute.self)
}
