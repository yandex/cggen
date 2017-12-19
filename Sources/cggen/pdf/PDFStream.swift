// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct PDFStream {
  let raw: CGPDFStreamRef
  let dict: [String: PDFObject]
  let data: Data
  let format: CGPDFDataFormat

  init?(obj: CGPDFObjectRef) {
    var streamPtr: CGPDFStreamRef?
    var format = CGPDFDataFormat.raw
    guard CGPDFObjectGetValue(obj, .stream, &streamPtr),
      let raw = streamPtr,
      let data = CGPDFStreamCopyData(raw, &format) as Data?,
      let dict = CGPDFStreamGetDictionary(raw)
    else { return nil }

    self.raw = raw
    self.data = data
    self.dict = PDFObject.processDict(dict)
    self.format = format
  }

  var rawDict: CGPDFDictionaryRef {
    return CGPDFStreamGetDictionary(raw)!
  }
}
