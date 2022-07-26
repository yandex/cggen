import CoreGraphics
import Foundation

import Base

public enum PDFParser {
  public static func parse(pdfURL: CFURL) throws -> [PDFPage] {
    guard let pdfDoc = CGPDFDocument(pdfURL) else {
      throw Error.parsingError()
    }
    return try pdfDoc.pages.map(PDFPage.init(page:))
  }
}

extension CGPDFDocument {
  var pages: [CGPDFPage] {
    (1...numberOfPages).map { page(at: $0)! }
  }
}
