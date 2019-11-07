// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import Foundation

public enum PDFParser {
  public static func parse(pdfURL: CFURL) -> [PDFPage] {
    guard let pdfDoc = CGPDFDocument(pdfURL) else {
      fatalError("Could not open pdf file at: \(pdfURL)")
    }
    return pdfDoc.pages.map {
      PDFPage(page: $0)!
    }
  }
}

extension CGPDFDocument {
  var pages: [CGPDFPage] {
    (1...numberOfPages).map { page(at: $0)! }
  }
}
