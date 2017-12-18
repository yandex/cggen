// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct PDFXObject {
  let dict: [String: PDFObject]
  let format: CGPDFDataFormat
  let data: Data
  init?(obj: PDFObject) {
    guard case let .stream(dict, format, data) = obj else { return nil }
    self.dict = dict
    self.format = format
    self.data = data
  }
}
