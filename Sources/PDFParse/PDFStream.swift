// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

struct PDFStream {
  let raw: CGPDFStreamRef
  let dict: [String: PDFObject]
  let data: Data
  let format: CGPDFDataFormat

  init?(obj: CGPDFObjectRef) {
    guard let raw = obj.stream,
      let (data, format) = raw.dataAndFormat,
      let dict = raw.dictionary
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

private extension CGPDFObjectRef {
  var stream: CGPDFStreamRef? {
    var streamPtr: CGPDFStreamRef?
    guard CGPDFObjectGetValue(self, .stream, &streamPtr) else {
      return nil
    }
    return streamPtr
  }
}

private extension CGPDFStreamRef {
  var dataAndFormat: (Data, CGPDFDataFormat)? {
    var format = CGPDFDataFormat.raw
    guard let data = CGPDFStreamCopyData(self, &format) as Data? else {
      return nil
    }
    return (data, format)
  }

  var dictionary: CGPDFDictionaryRef? {
    return CGPDFStreamGetDictionary(self)
  }
}
