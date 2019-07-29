// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import ArgParse
import Base
import Foundation

struct Args {
  let outDir: String
  let scale: Double
  let suffix: String
  let files: [String]
}

func parseArgs() -> Args {
  let parser = ArgParser(
    helptext: "Tool for converting pdf to png",
    version: "0.1"
  )
  let outDirKey = "out"
  let scaleKey = "scale"
  let suffixKey = "suffix"
  parser.newString(outDirKey)
  parser.newDouble(scaleKey)
  parser.newString(suffixKey)
  parser.parse()
  return Args(
    outDir: parser.getString(outDirKey),
    scale: parser.getDouble(scaleKey),
    suffix: parser.getString(suffixKey),
    files: parser.getArgs()
  )
}

func main(args: Args) -> Int32 {
  args.files
    .map(URL.init(fileURLWithPath:))
    .concurrentMap { ($0.deletingPathExtension().lastPathComponent, CGPDFDocument($0 as CFURL)!) }
    .flatMap { $0.1.pages.appendToAll(a: $0.0) }
    .concurrentMap { ($0.0, $0.1.render(scale: args.scale.cgfloat)!) }
    .forEach { (name: String, img: CGImage) in
      let url = URL(fileURLWithPath: args.outDir)
        .appendingPathComponent("\(name)\(args.suffix).png") as CFURL
      try! img.write(fileURL: url)
    }
  return 0
}

exit(main(args: parseArgs()))
