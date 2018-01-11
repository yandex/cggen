// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Base
import CoreGraphics

struct PDFFunction {
  struct Point {
    let arg: CGFloat
    let value: [CGFloat]
  }

  enum FunctionType: Int {
    case sampled = 0
    case exponentialInterpolation = 2
    case stitching = 3
    case postsciptCalculator = 4
  }
  static let supportedTypes: Set<FunctionType> = [ .sampled ]

  enum ParseError: Error {
    case noFunctionType
    case unsupportedFunctionType(FunctionType)
    case other
  }

  let rangeDim: Int
  let domainDim: Int
  let range: [(CGFloat, CGFloat)]
  let domain: [(CGFloat, CGFloat)]
  let size: [Int]
  let length: Int
  let points: [Point]

  init(obj: PDFObject) throws {
    guard let dict = obj.dictFromDictOrStream,
      let functionTypeRaw = dict["FunctionType"]?.intValue,
      let functionType = FunctionType(rawValue: functionTypeRaw)
      else { throw ParseError.noFunctionType }
    guard PDFFunction.supportedTypes.contains(functionType)
      else { throw ParseError.unsupportedFunctionType(functionType) }

    guard case let .stream(stream) = obj,
      let rangeObj = stream.dict["Range"],
      case let .array(rangeArray) = rangeObj,
      let rangeRaw = rangeArray.map({ $0.realFromIntOrReal() }).unwrap(),
      let sizeObj = stream.dict["Size"],
      let size = sizeObj.integerArray(),
      let length = stream.dict["Length"]?.intValue,
      let domainObj = stream.dict["Domain"],
      case let .array(domainArray) = domainObj,
      let domainRaw = domainArray.map({ $0.realFromIntOrReal() }).unwrap(),
      let bitsPerSample = stream.dict["BitsPerSample"]?.intValue
    else { throw ParseError.other }
    precondition(stream.format == .raw)

    let range = rangeRaw.splitBy(subSize: 2).map { ($0[0], $0[1]) }
    let rangeDim = range.count
    let domain = domainRaw.splitBy(subSize: 2).map { ($0[0], $0[1]) }
    let domainDim = domain.count
    precondition(domainDim == 1, "Only R1 -> RN supported")

    precondition(bitsPerSample == 8, "Only UInt8 supported")
    let samples = [UInt8](stream.data).map { CGFloat($0) / CGFloat(UInt8.max) }
    let values = samples.splitBy(subSize: rangeDim)
    let points = (0..<size[0]).map { (s) -> Point in
      let start = domain[0].0
      let end = domain[0].1
      let step = (end - start) / CGFloat(size[0] - 1)
      let current = start + CGFloat(s) * step
      return Point(arg: current, value: values[s])
    }.removeIntermediates()

    self.range = range
    self.rangeDim = rangeDim
    self.domain = domain
    self.domainDim = domainDim
    self.size = size
    self.length = length
    self.points = points
  }
}

extension PDFFunction.Point: LinearInterpolatable {
  typealias AbscissaType = CGFloat
  var abscissa: CGFloat { return arg }
  func near(_ other: PDFFunction.Point) -> Bool {
    let squareDistance = zip(value, other.value)
      .reduce(0) { (acc, pair) -> CGFloat in
        let d = pair.0 - pair.1
        return acc + d * d
      }
    return squareDistance < 0.001
  }
  static func linearInterpolate(from lhs: PDFFunction.Point,
                                to rhs: PDFFunction.Point,
                                at x: CGFloat) -> PDFFunction.Point {
    precondition(lhs.value.count == rhs.value.count)
    let outN = lhs.value.count
    let out = (0..<outN).map { (i) -> CGFloat in
      let x1 = lhs.arg
      let x2 = rhs.arg
      let y1 = lhs.value[i]
      let y2 = rhs.value[i]
      let k = (y1 - y2) / (x1 - x2)
      let b = y1 - k * x1
      return k * x + b
    }
    return PDFFunction.Point(arg: x, value: out)
  }
}
