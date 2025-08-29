import ArgumentParser
import CGGenBytecode
import CGGenBytecodeDecoding
import CoreGraphics
import Foundation

struct DecodeCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "decode",
    abstract: "Decode and display bytecode from generated files"
  )

  @Argument(help: "Path to the generated .m or .swift file")
  var inputFile: String
  
  struct DrawingInfo {
    let name: String
    let startIndex: Int
    let endIndex: Int
    let size: CGSize
  }

  mutating func run() throws {
    let url = URL(fileURLWithPath: inputFile)
    let content = try String(contentsOf: url, encoding: .utf8)

    let fileExtension = url.pathExtension.lowercased()
    guard fileExtension == "m" || fileExtension == "swift" else {
      throw ValidationError("Input file must be .m or .swift")
    }

    let bytecodeArrays = try extractBytecode(from: content, fileType: fileExtension)

    if bytecodeArrays.isEmpty {
      print("No bytecode arrays found")
      return
    }

    for array in bytecodeArrays {
      let decodedBytes = try decodeBytecode(
        array.data,
        compressed: array.isCompressed,
        decompressedSize: array.decompressedSize
      )
      
      // Extract drawing segments
      let drawings = extractDrawings(from: content, fileType: fileExtension)
      
      if !drawings.isEmpty && array.isCompressed {
        // Display bytecode segments per drawing
        for drawing in drawings {
          print("\n" + String(repeating: "=", count: 80))
          print("Drawing: \(drawing.name)")
          print("Size: \(drawing.size.width) x \(drawing.size.height)")
          print("Bytecode range: [\(drawing.startIndex)...\(drawing.endIndex)]")
          print(String(repeating: "-", count: 80))
          
          // Decode only the segment for this drawing
          try decodeSegment(decodedBytes, startIndex: drawing.startIndex, endIndex: drawing.endIndex)
        }
        print("\n" + String(repeating: "=", count: 80))
      } else {
        // Fallback to full bytecode display
        print("\nBytecode \(decodedBytes.count) bytes:")
        print(formatBytecodeAsHex(decodedBytes))
        print("\nCommands:")
        try decodeCommands(decodedBytes)
      }
      print()
    }
  }

  private func extractBytecode(from content: String, fileType: String) throws -> [BytecodeArray] {
    if fileType == "m" {
      return try parseObjectiveCFile(content)
    } else if fileType == "swift" {
      return try parseSwiftFile(content)
    } else {
      throw ValidationError("Unsupported file type: \(fileType)")
    }
  }

  private func parseObjectiveCFile(_ content: String) throws -> [BytecodeArray] {
    var arrays: [BytecodeArray] = []

    let pattern = #"static const uint8_t (\w+)\[\].*?=\s*\{([^}]+)\}"#
    let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))

    for match in matches {
      guard let nameRange = Range(match.range(at: 1), in: content),
            let dataRange = Range(match.range(at: 2), in: content) else {
        continue
      }

      let name = String(content[nameRange])
      let dataString = String(content[dataRange])
      let bytes = parseHexBytes(from: dataString)

      let isCompressed = name == "mergedBytecodes"
      var decompressedSize: Int?

      if isCompressed {
        let sizePattern = #"runMergedBytecode\(context, \w+, (\d+),"#
        let sizeRegex = try NSRegularExpression(pattern: sizePattern)
        if let sizeMatch = sizeRegex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
           let sizeRange = Range(sizeMatch.range(at: 1), in: content) {
          decompressedSize = Int(String(content[sizeRange]))
        }
      }

      if !bytes.isEmpty {
        arrays.append(BytecodeArray(
          name: name,
          data: bytes,
          isCompressed: isCompressed,
          decompressedSize: decompressedSize
        ))
      }
    }

    return arrays
  }

  private func parseSwiftFile(_ content: String) throws -> [BytecodeArray] {
    var arrays: [BytecodeArray] = []

    let pattern = #"(?:static )?(?:let|var) (\w+):\s*\[UInt8\]\s*=\s*\[([^\]]+)\]"#
    let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))

    for match in matches {
      guard let nameRange = Range(match.range(at: 1), in: content),
            let dataRange = Range(match.range(at: 2), in: content) else {
        continue
      }

      let name = String(content[nameRange])
      let dataString = String(content[dataRange])
      let bytes = parseHexBytes(from: dataString)
      let isCompressed = name.contains("merged") || name.contains("compressed")

      arrays.append(BytecodeArray(
        name: name,
        data: bytes,
        isCompressed: isCompressed,
        decompressedSize: nil
      ))
    }

    return arrays
  }

  private func parseHexBytes(from string: String) -> [UInt8] {
    var bytes: [UInt8] = []
    let pattern = #"0x([0-9A-Fa-f]{1,2})"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let matches = regex.matches(in: string, options: [], range: NSRange(string.startIndex..., in: string))

    for match in matches {
      guard let hexRange = Range(match.range(at: 1), in: string) else {
        continue
      }
      let hexString = String(string[hexRange])
      if let byte = UInt8(hexString, radix: 16) {
        bytes.append(byte)
      }
    }

    return bytes
  }

  private func decodeBytecode(_ data: [UInt8], compressed: Bool, decompressedSize: Int?) throws -> [UInt8] {
    if compressed {
      guard let decompSize = decompressedSize else {
        throw ValidationError("Compressed bytecode requires decompressed size")
      }
      return try data.withUnsafeBytes { bytes in
        try CGGenBytecodeDecoding.decompressBytecode(
          bytes.bindMemory(to: UInt8.self).baseAddress!,
          data.count,
          decompSize
        )
      }
    } else {
      return data
    }
  }

  private func formatBytecodeAsHex(_ bytes: [UInt8]) -> String {
    let bytesPerLine = 16
    var result = ""

    for (index, byte) in bytes.enumerated() {
      if index > 0, index % bytesPerLine == 0 {
        result += "\n"
      }
      result += String(format: "%02X ", byte)
    }

    return result
  }

  private func decodeCommands(_ data: [UInt8]) throws {
    try data.withUnsafeBytes { bytes in
      var bytecode = Bytecode(base: bytes.baseAddress!, count: data.count)
      
      // Display offset in hex format
      func printCmd(_ cmd: String, context: BytecodeVisitor.Context) {
        print(String(format: "0x%05X ", context.offset) + cmd)
      }
      
      try BytecodeVisitor.visit(
        &bytecode,
        onSaveGState: { _, context in printCmd("SaveGState()", context: context) },
        onRestoreGState: { _, context in printCmd("RestoreGState()", context: context) },
        onMoveTo: { point, context in printCmd("MoveTo(\(formatFloat(point.x)), \(formatFloat(point.y)))", context: context) },
        onLineTo: { point, context in printCmd("LineTo(\(formatFloat(point.x)), \(formatFloat(point.y)))", context: context) },
        onCurveTo: { curve, context in 
          printCmd("CurveTo(\(formatFloat(curve.to.x)), \(formatFloat(curve.to.y)), \(formatFloat(curve.control1.x)), \(formatFloat(curve.control1.y)), \(formatFloat(curve.control2.x)), \(formatFloat(curve.control2.y)))", context: context)
        },
        onQuadCurveTo: { curve, context in
          printCmd("QuadCurveTo(\(formatFloat(curve.to.x)), \(formatFloat(curve.to.y)), \(formatFloat(curve.control.x)), \(formatFloat(curve.control.y)))", context: context)
        },
        onClosePath: { _, context in printCmd("ClosePath()", context: context) },
        onAppendRectangle: { rect, context in
          printCmd("AppendRectangle(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onAppendRoundedRect: { args, context in
          let (rect, rx, ry) = args
          printCmd("AppendRoundedRect(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)), \(formatFloat(rx)), \(formatFloat(ry)))", context: context)
        },
        onAddEllipse: { rect, context in
          printCmd("AddEllipse(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onAddArc: { args, context in
          let (center, radius, startAngle, endAngle, clockwise) = args
          printCmd("AddArc(\(formatFloat(center.x)), \(formatFloat(center.y)), \(formatFloat(radius)), \(formatFloat(startAngle)), \(formatFloat(endAngle)), \(clockwise ? 1 : 0))", context: context)
        },
        onFill: { _, context in printCmd("Fill()", context: context) },
        onFillWithRule: { rule, context in
          printCmd("FillWithRule(\(rule == .winding ? "winding" : "evenOdd"))", context: context)
        },
        onStroke: { _, context in printCmd("Stroke()", context: context) },
        onFillAndStroke: { _, context in printCmd("FillAndStroke()", context: context) },
        onDrawPath: { mode, context in
          printCmd("DrawPath(\(mode))", context: context)
        },
        onFillColor: { color, context in
          printCmd("FillColor(\(color.red), \(color.green), \(color.blue))", context: context)
        },
        onStrokeColor: { color, context in
          printCmd("StrokeColor(\(color.red), \(color.green), \(color.blue))", context: context)
        },
        onFillAlpha: { alpha, context in printCmd("FillAlpha(\(formatFloat(Float32(alpha))))", context: context) },
        onStrokeAlpha: { alpha, context in printCmd("StrokeAlpha(\(formatFloat(Float32(alpha))))", context: context) },
        onFillNone: { _, context in printCmd("FillNone()", context: context) },
        onStrokeNone: { _, context in printCmd("StrokeNone()", context: context) },
        onLineWidth: { width, context in printCmd("LineWidth(\(formatFloat(Float32(width))))", context: context) },
        onLineCapStyle: { cap, context in
          printCmd("LineCapStyle(\(cap))", context: context)
        },
        onLineJoinStyle: { join, context in
          printCmd("LineJoinStyle(\(join))", context: context)
        },
        onMiterLimit: { limit, context in printCmd("MiterLimit(\(formatFloat(Float32(limit))))", context: context) },
        onDash: { pattern, context in
          let lengths = pattern.lengths.map { formatFloat(Float32($0)) }.joined(separator: ", ")
          printCmd("Dash(\(formatFloat(Float32(pattern.phase))), [\(lengths)])", context: context)
        },
        onDashPhase: { phase, context in printCmd("DashPhase(\(formatFloat(Float32(phase))))", context: context) },
        onDashLengths: { lengths, context in
          let lengthsStr = lengths.map { formatFloat(Float32($0)) }.joined(separator: ", ")
          printCmd("DashLengths([\(lengthsStr)])", context: context)
        },
        onConcatCTM: { transform, context in
          printCmd("ConcatCTM(\(formatFloat(Float32(transform.a))), \(formatFloat(Float32(transform.b))), \(formatFloat(Float32(transform.c))), \(formatFloat(Float32(transform.d))), \(formatFloat(Float32(transform.tx))), \(formatFloat(Float32(transform.ty))))", context: context)
        },
        onGlobalAlpha: { alpha, context in printCmd("GlobalAlpha(\(formatFloat(Float32(alpha))))", context: context) },
        onSetGlobalAlphaToFillAlpha: { _, context in printCmd("SetGlobalAlphaToFillAlpha()", context: context) },
        onBlendMode: { mode, context in
          printCmd("BlendMode(\(mode))", context: context)
        },
        onFillLinearGradient: { args, context in
          let (id, options) = args
          printCmd("FillLinearGradient(\(id), \(formatFloat(options.start.x)), \(formatFloat(options.start.y)), \(formatFloat(options.end.x)), \(formatFloat(options.end.y)))", context: context)
        },
        onFillRadialGradient: { args, context in
          let (id, options) = args
          printCmd("FillRadialGradient(\(id), \(formatFloat(options.startCenter.x)), \(formatFloat(options.startCenter.y)), \(formatFloat(Float32(options.startRadius))), \(formatFloat(options.endCenter.x)), \(formatFloat(options.endCenter.y)), \(formatFloat(Float32(options.endRadius))))", context: context)
        },
        onStrokeLinearGradient: { args, context in
          let (id, options) = args
          printCmd("StrokeLinearGradient(\(id), \(formatFloat(options.start.x)), \(formatFloat(options.start.y)), \(formatFloat(options.end.x)), \(formatFloat(options.end.y)))", context: context)
        },
        onStrokeRadialGradient: { args, context in
          let (id, options) = args
          printCmd("StrokeRadialGradient(\(id), \(formatFloat(options.startCenter.x)), \(formatFloat(options.startCenter.y)), \(formatFloat(Float32(options.startRadius))), \(formatFloat(options.endCenter.x)), \(formatFloat(options.endCenter.y)), \(formatFloat(Float32(options.endRadius))))", context: context)
        },
        onLinearGradient: { args, context in
          let (id, options) = args
          printCmd("LinearGradient(\(id), \(formatFloat(options.start.x)), \(formatFloat(options.start.y)), \(formatFloat(options.end.x)), \(formatFloat(options.end.y)))", context: context)
        },
        onRadialGradient: { args, context in
          let (id, options) = args
          printCmd("RadialGradient(\(id), \(formatFloat(options.startCenter.x)), \(formatFloat(options.startCenter.y)), \(formatFloat(Float32(options.startRadius))), \(formatFloat(options.endCenter.x)), \(formatFloat(options.endCenter.y)), \(formatFloat(Float32(options.endRadius))))", context: context)
        },
        onClip: { _, context in printCmd("Clip()", context: context) },
        onClipWithRule: { rule, context in
          printCmd("ClipWithRule(\(rule == .winding ? "winding" : "evenOdd"))", context: context)
        },
        onClipToRect: { rect, context in
          printCmd("ClipToRect(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onBeginTransparencyLayer: { _, context in printCmd("BeginTransparencyLayer()", context: context) },
        onEndTransparencyLayer: { _, context in printCmd("EndTransparencyLayer()", context: context) },
        onShadow: { shadow, context in
          printCmd("Shadow(\(formatFloat(shadow.offset.width)), \(formatFloat(shadow.offset.height)), \(formatFloat(Float32(shadow.blur))), \(shadow.color.red), \(shadow.color.green), \(shadow.color.blue), \(formatFloat(Float32(shadow.color.alpha))))", context: context)
        },
        onSubrouteWithId: { id, context in printCmd("SubrouteWithId(\(id))", context: context) },
        onFlatness: { flatness, context in printCmd("Flatness(\(formatFloat(Float32(flatness))))", context: context) },
        onFillEllipse: { rect, context in
          printCmd("FillEllipse(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onColorRenderingIntent: { intent, context in
          printCmd("ColorRenderingIntent(\(intent))", context: context)
        },
        onFillRule: { rule, context in
          printCmd("FillRule(\(rule == .winding ? "winding" : "evenOdd"))", context: context)
        },
        onReplacePathWithStrokePath: { _, context in printCmd("ReplacePathWithStrokePath()", context: context) },
        onLines: { points, context in
          let pointsStr = points.map { "\(formatFloat($0.x)), \(formatFloat($0.y))" }.joined(separator: ", ")
          printCmd("Lines(\(pointsStr))", context: context)
        }
      )
    }
  }

  private func formatFloat(_ value: Float32) -> String {
    if value == Float32(Int(value)) {
      String(Int(value))
    } else {
      String(format: "%.2f", value)
    }
  }

  private func formatFloat(_ value: CGFloat) -> String {
    formatFloat(Float32(value))
  }
  
  private func extractDrawings(from content: String, fileType: String) -> [DrawingInfo] {
    var drawings: [DrawingInfo] = []
    
    if fileType == "m" {
      // Parse Objective-C file for drawing definitions
      let pattern = #"static void YXDraw(\w+)ImageInContext\(CGContextRef context\) \{\s*runMergedBytecode\(context, mergedBytecodes, \d+, \d+, (\d+), (\d+)\);\s*\}const YXAttachmentsKitGeneratedImageDescriptor kYXAttachmentsKit(\w+)Descriptor = \{\s*\{ \(CGFloat\)([0-9.]+), \(CGFloat\)([0-9.]+) \}"#
      let regex = try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
      let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
      
      for match in matches {
        guard let nameRange = Range(match.range(at: 1), in: content),
              let startRange = Range(match.range(at: 2), in: content),
              let endRange = Range(match.range(at: 3), in: content),
              let widthRange = Range(match.range(at: 5), in: content),
              let heightRange = Range(match.range(at: 6), in: content) else {
          continue
        }
        
        let name = String(content[nameRange])
        let startIndex = Int(String(content[startRange])) ?? 0
        let endIndex = Int(String(content[endRange])) ?? 0
        let width = Double(String(content[widthRange])) ?? 0
        let height = Double(String(content[heightRange])) ?? 0
        
        drawings.append(DrawingInfo(
          name: name,
          startIndex: startIndex,
          endIndex: endIndex,
          size: CGSize(width: width, height: height)
        ))
      }
    } else if fileType == "swift" {
      // Parse Swift file for drawing definitions
      let pattern = #"static let (\w+) = Drawing\(size: CGSize\(width: ([0-9.]+), height: ([0-9.]+)\), bytecode: \(\(mergedBytecodes\), (\d+), (\d+)\)\)"#
      let regex = try! NSRegularExpression(pattern: pattern, options: [])
      let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
      
      for match in matches {
        guard let nameRange = Range(match.range(at: 1), in: content),
              let widthRange = Range(match.range(at: 2), in: content),
              let heightRange = Range(match.range(at: 3), in: content),
              let startRange = Range(match.range(at: 4), in: content),
              let endRange = Range(match.range(at: 5), in: content) else {
          continue
        }
        
        let name = String(content[nameRange])
        let width = Double(String(content[widthRange])) ?? 0
        let height = Double(String(content[heightRange])) ?? 0
        let startIndex = Int(String(content[startRange])) ?? 0
        let endIndex = Int(String(content[endRange])) ?? 0
        
        drawings.append(DrawingInfo(
          name: name,
          startIndex: startIndex,
          endIndex: endIndex,
          size: CGSize(width: width, height: height)
        ))
      }
    }
    
    return drawings.sorted { $0.startIndex < $1.startIndex }
  }
  
  private func decodeSegment(_ fullBytecode: [UInt8], startIndex: Int, endIndex: Int) throws {
    // Create a slice of bytecode for this segment
    guard startIndex < fullBytecode.count && endIndex <= fullBytecode.count && startIndex < endIndex else {
      print("Invalid segment range: [\(startIndex)...\(endIndex)] for bytecode of size \(fullBytecode.count)")
      return
    }
    
    let segmentSize = endIndex - startIndex + 1
    let segment = Array(fullBytecode[startIndex...endIndex])
    
    print("Segment bytecode (\(segmentSize) bytes):")
    print(formatBytecodeAsHex(segment))
    print("\nCommands:")
    
    // Decode the segment  
    try segment.withUnsafeBytes { bytes in
      var bytecode = Bytecode(base: bytes.baseAddress!, count: segment.count)
      
      // Display offset in hex format relative to segment start
      func printCmd(_ cmd: String, context: BytecodeVisitor.Context) {
        let absoluteOffset = startIndex + context.offset
        print(String(format: "0x%05X ", absoluteOffset) + cmd)
      }
      
      try BytecodeVisitor.visit(
        &bytecode,
        onSaveGState: { _, context in printCmd("SaveGState()", context: context) },
        onRestoreGState: { _, context in printCmd("RestoreGState()", context: context) },
        onMoveTo: { point, context in printCmd("MoveTo(\(formatFloat(point.x)), \(formatFloat(point.y)))", context: context) },
        onLineTo: { point, context in printCmd("LineTo(\(formatFloat(point.x)), \(formatFloat(point.y)))", context: context) },
        onCurveTo: { curve, context in 
          printCmd("CurveTo(\(formatFloat(curve.to.x)), \(formatFloat(curve.to.y)), \(formatFloat(curve.control1.x)), \(formatFloat(curve.control1.y)), \(formatFloat(curve.control2.x)), \(formatFloat(curve.control2.y)))", context: context)
        },
        onQuadCurveTo: { curve, context in
          printCmd("QuadCurveTo(\(formatFloat(curve.to.x)), \(formatFloat(curve.to.y)), \(formatFloat(curve.control.x)), \(formatFloat(curve.control.y)))", context: context)
        },
        onClosePath: { _, context in printCmd("ClosePath()", context: context) },
        onAppendRectangle: { rect, context in
          printCmd("AppendRectangle(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onAppendRoundedRect: { args, context in
          let (rect, rx, ry) = args
          printCmd("AppendRoundedRect(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)), \(formatFloat(rx)), \(formatFloat(ry)))", context: context)
        },
        onAddEllipse: { rect, context in
          printCmd("AddEllipse(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onAddArc: { args, context in
          let (center, radius, startAngle, endAngle, clockwise) = args
          printCmd("AddArc(\(formatFloat(center.x)), \(formatFloat(center.y)), \(formatFloat(radius)), \(formatFloat(startAngle)), \(formatFloat(endAngle)), \(clockwise ? 1 : 0))", context: context)
        },
        onFill: { _, context in printCmd("Fill()", context: context) },
        onFillWithRule: { rule, context in
          printCmd("FillWithRule(\(rule == .winding ? "winding" : "evenOdd"))", context: context)
        },
        onStroke: { _, context in printCmd("Stroke()", context: context) },
        onFillAndStroke: { _, context in printCmd("FillAndStroke()", context: context) },
        onDrawPath: { mode, context in
          printCmd("DrawPath(\(mode))", context: context)
        },
        onFillColor: { color, context in
          printCmd("FillColor(\(color.red), \(color.green), \(color.blue))", context: context)
        },
        onStrokeColor: { color, context in
          printCmd("StrokeColor(\(color.red), \(color.green), \(color.blue))", context: context)
        },
        onFillAlpha: { alpha, context in printCmd("FillAlpha(\(formatFloat(Float32(alpha))))", context: context) },
        onStrokeAlpha: { alpha, context in printCmd("StrokeAlpha(\(formatFloat(Float32(alpha))))", context: context) },
        onFillNone: { _, context in printCmd("FillNone()", context: context) },
        onStrokeNone: { _, context in printCmd("StrokeNone()", context: context) },
        onLineWidth: { width, context in printCmd("LineWidth(\(formatFloat(Float32(width))))", context: context) },
        onLineCapStyle: { cap, context in
          printCmd("LineCapStyle(\(cap))", context: context)
        },
        onLineJoinStyle: { join, context in
          printCmd("LineJoinStyle(\(join))", context: context)
        },
        onMiterLimit: { limit, context in printCmd("MiterLimit(\(formatFloat(Float32(limit))))", context: context) },
        onDash: { pattern, context in
          let lengths = pattern.lengths.map { formatFloat(Float32($0)) }.joined(separator: ", ")
          printCmd("Dash(\(formatFloat(Float32(pattern.phase))), [\(lengths)])", context: context)
        },
        onDashPhase: { phase, context in printCmd("DashPhase(\(formatFloat(Float32(phase))))", context: context) },
        onDashLengths: { lengths, context in
          let lengthsStr = lengths.map { formatFloat(Float32($0)) }.joined(separator: ", ")
          printCmd("DashLengths([\(lengthsStr)])", context: context)
        },
        onConcatCTM: { transform, context in
          printCmd("ConcatCTM(\(formatFloat(Float32(transform.a))), \(formatFloat(Float32(transform.b))), \(formatFloat(Float32(transform.c))), \(formatFloat(Float32(transform.d))), \(formatFloat(Float32(transform.tx))), \(formatFloat(Float32(transform.ty))))", context: context)
        },
        onGlobalAlpha: { alpha, context in printCmd("GlobalAlpha(\(formatFloat(Float32(alpha))))", context: context) },
        onSetGlobalAlphaToFillAlpha: { _, context in printCmd("SetGlobalAlphaToFillAlpha()", context: context) },
        onBlendMode: { mode, context in
          printCmd("BlendMode(\(mode))", context: context)
        },
        onFillLinearGradient: { args, context in
          let (id, options) = args
          printCmd("FillLinearGradient(\(id), \(formatFloat(options.start.x)), \(formatFloat(options.start.y)), \(formatFloat(options.end.x)), \(formatFloat(options.end.y)))", context: context)
        },
        onFillRadialGradient: { args, context in
          let (id, options) = args
          printCmd("FillRadialGradient(\(id), \(formatFloat(options.startCenter.x)), \(formatFloat(options.startCenter.y)), \(formatFloat(Float32(options.startRadius))), \(formatFloat(options.endCenter.x)), \(formatFloat(options.endCenter.y)), \(formatFloat(Float32(options.endRadius))))", context: context)
        },
        onStrokeLinearGradient: { args, context in
          let (id, options) = args
          printCmd("StrokeLinearGradient(\(id), \(formatFloat(options.start.x)), \(formatFloat(options.start.y)), \(formatFloat(options.end.x)), \(formatFloat(options.end.y)))", context: context)
        },
        onStrokeRadialGradient: { args, context in
          let (id, options) = args
          printCmd("StrokeRadialGradient(\(id), \(formatFloat(options.startCenter.x)), \(formatFloat(options.startCenter.y)), \(formatFloat(Float32(options.startRadius))), \(formatFloat(options.endCenter.x)), \(formatFloat(options.endCenter.y)), \(formatFloat(Float32(options.endRadius))))", context: context)
        },
        onLinearGradient: { args, context in
          let (id, options) = args
          printCmd("LinearGradient(\(id), \(formatFloat(options.start.x)), \(formatFloat(options.start.y)), \(formatFloat(options.end.x)), \(formatFloat(options.end.y)))", context: context)
        },
        onRadialGradient: { args, context in
          let (id, options) = args
          printCmd("RadialGradient(\(id), \(formatFloat(options.startCenter.x)), \(formatFloat(options.startCenter.y)), \(formatFloat(Float32(options.startRadius))), \(formatFloat(options.endCenter.x)), \(formatFloat(options.endCenter.y)), \(formatFloat(Float32(options.endRadius))))", context: context)
        },
        onClip: { _, context in printCmd("Clip()", context: context) },
        onClipWithRule: { rule, context in
          printCmd("ClipWithRule(\(rule == .winding ? "winding" : "evenOdd"))", context: context)
        },
        onClipToRect: { rect, context in
          printCmd("ClipToRect(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onBeginTransparencyLayer: { _, context in printCmd("BeginTransparencyLayer()", context: context) },
        onEndTransparencyLayer: { _, context in printCmd("EndTransparencyLayer()", context: context) },
        onShadow: { shadow, context in
          printCmd("Shadow(\(formatFloat(shadow.offset.width)), \(formatFloat(shadow.offset.height)), \(formatFloat(Float32(shadow.blur))), \(shadow.color.red), \(shadow.color.green), \(shadow.color.blue), \(formatFloat(Float32(shadow.color.alpha))))", context: context)
        },
        onSubrouteWithId: { id, context in printCmd("SubrouteWithId(\(id))", context: context) },
        onFlatness: { flatness, context in printCmd("Flatness(\(formatFloat(Float32(flatness))))", context: context) },
        onFillEllipse: { rect, context in
          printCmd("FillEllipse(\(formatFloat(rect.origin.x)), \(formatFloat(rect.origin.y)), \(formatFloat(rect.size.width)), \(formatFloat(rect.size.height)))", context: context)
        },
        onColorRenderingIntent: { intent, context in
          printCmd("ColorRenderingIntent(\(intent))", context: context)
        },
        onFillRule: { rule, context in
          printCmd("FillRule(\(rule == .winding ? "winding" : "evenOdd"))", context: context)
        },
        onReplacePathWithStrokePath: { _, context in printCmd("ReplacePathWithStrokePath()", context: context) },
        onLines: { points, context in
          let pointsStr = points.map { "\(formatFloat($0.x)), \(formatFloat($0.y))" }.joined(separator: ", ")
          printCmd("Lines(\(pointsStr))", context: context)
        }
      )
    }
  }
}

private struct BytecodeArray {
  let name: String
  let data: [UInt8]
  let isCompressed: Bool
  let decompressedSize: Int?
}

struct ValidationError: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }
}