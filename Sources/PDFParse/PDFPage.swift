import CoreGraphics

import Base

public typealias PDFColor = RGBColor<CGPDFReal>

public struct PDFPage {
  public let resources: PDFResources
  public let operators: [PDFOperator]
  public let bbox: CGRect

  internal init(page: CGPDFPage) throws {
    let stream = CGPDFContentStreamCreateWithPage(page)
    let operators = try PDFContentStreamParser
      .parse(stream: CGPDFContentStreamCreateWithPage(page))

    guard let pageDictRaw = page.dictionary,
          let pageDictionary = PDFObject.processDict(pageDictRaw)["Resources"]
    else { throw Error.parsingError() }
    let resources = try PDFResources(obj: pageDictionary, parentStream: stream)

    let bbox = page.getBoxRect(.mediaBox)

    self.operators = operators
    self.resources = resources
    self.bbox = bbox
  }
}
