import CGGenBytecode
import CoreGraphics
import Foundation

public enum BytecodeVisitor {
  public struct Context {
    public let offset: Int
    public let commandIndex: Int
    public let totalSize: Int
    
    public init(offset: Int, commandIndex: Int, totalSize: Int) {
      self.offset = offset
      self.commandIndex = commandIndex
      self.totalSize = totalSize
    }
  }

  public typealias Visitor<T> = (T, Context) throws -> Void
  public typealias Cmd = DrawCommand

  @inlinable public static func visit(
    _ bytecode: inout Bytecode,
    onSaveGState: Visitor<Cmd.SaveGStateArgs>,
    onRestoreGState: Visitor<Cmd.RestoreGStateArgs>,
    onMoveTo: Visitor<Cmd.MoveToArgs>,
    onLineTo: Visitor<Cmd.LineToArgs>,
    onCurveTo: Visitor<Cmd.CurveToArgs>,
    onQuadCurveTo: Visitor<Cmd.QuadCurveToArgs>,
    onClosePath: Visitor<Cmd.ClosePathArgs>,
    onAppendRectangle: Visitor<Cmd.AppendRectangleArgs>,
    onAppendRoundedRect: Visitor<Cmd.AppendRoundedRectArgs>,
    onAddEllipse: Visitor<Cmd.AddEllipseArgs>,
    onAddArc: Visitor<Cmd.AddArcArgs>,
    onFill: Visitor<Cmd.FillArgs>,
    onFillWithRule: Visitor<Cmd.FillWithRuleArgs>,
    onStroke: Visitor<Cmd.StrokeArgs>,
    onFillAndStroke: Visitor<Cmd.FillAndStrokeArgs>,
    onDrawPath: Visitor<Cmd.DrawPathArgs>,
    onFillColor: Visitor<Cmd.FillColorArgs>,
    onStrokeColor: Visitor<Cmd.StrokeColorArgs>,
    onFillAlpha: Visitor<Cmd.FillAlphaArgs>,
    onStrokeAlpha: Visitor<Cmd.StrokeAlphaArgs>,
    onFillNone: Visitor<Cmd.FillNoneArgs>,
    onStrokeNone: Visitor<Cmd.StrokeNoneArgs>,
    onLineWidth: Visitor<Cmd.LineWidthArgs>,
    onLineCapStyle: Visitor<Cmd.LineCapStyleArgs>,
    onLineJoinStyle: Visitor<Cmd.LineJoinStyleArgs>,
    onMiterLimit: Visitor<Cmd.MiterLimitArgs>,
    onDash: Visitor<Cmd.DashArgs>,
    onDashPhase: Visitor<Cmd.DashPhaseArgs>,
    onDashLengths: Visitor<Cmd.DashLengthsArgs>,
    onConcatCTM: Visitor<Cmd.ConcatCTMArgs>,
    onGlobalAlpha: Visitor<Cmd.GlobalAlphaArgs>,
    onSetGlobalAlphaToFillAlpha: Visitor<Cmd.SetGlobalAlphaToFillAlphaArgs>,
    onBlendMode: Visitor<Cmd.BlendModeArgs>,
    onFillLinearGradient: Visitor<Cmd.FillLinearGradientArgs>,
    onFillRadialGradient: Visitor<Cmd.FillRadialGradientArgs>,
    onStrokeLinearGradient: Visitor<Cmd.StrokeLinearGradientArgs>,
    onStrokeRadialGradient: Visitor<Cmd.StrokeRadialGradientArgs>,
    onLinearGradient: Visitor<Cmd.LinearGradientArgs>,
    onRadialGradient: Visitor<Cmd.RadialGradientArgs>,
    onClip: Visitor<Cmd.ClipArgs>,
    onClipWithRule: Visitor<Cmd.ClipWithRuleArgs>,
    onClipToRect: Visitor<Cmd.ClipToRectArgs>,
    onBeginTransparencyLayer: Visitor<Cmd.BeginTransparencyLayerArgs>,
    onEndTransparencyLayer: Visitor<Cmd.EndTransparencyLayerArgs>,
    onShadow: Visitor<Cmd.ShadowArgs>,
    onSubrouteWithId: Visitor<Cmd.SubrouteWithIdArgs>,
    onFlatness: Visitor<Cmd.FlatnessArgs>,
    onFillEllipse: Visitor<Cmd.FillEllipseArgs>,
    onColorRenderingIntent: Visitor<Cmd.ColorRenderingIntentArgs>,
    onFillRule: Visitor<Cmd.FillRuleArgs>,
    onReplacePathWithStrokePath: Visitor<Cmd.ReplacePathWithStrokePathArgs>,
    onLines: Visitor<Cmd.LinesArgs>
  ) throws {
    let totalSize = bytecode.count
    var commandIndex = 0
    
    while bytecode.count > 0 {
      let currentOffset = totalSize - bytecode.count
      let commandStartOffset = currentOffset
      let command = try DrawCommand(bytecode: &bytecode)
      
      let context = Context(
        offset: commandStartOffset,
        commandIndex: commandIndex,
        totalSize: totalSize
      )
      commandIndex += 1

      switch command {
      case .saveGState:
        try onSaveGState((), context)
      case .restoreGState:
        try onRestoreGState((), context)
      case .moveTo:
        try onMoveTo(read(&bytecode), context)
      case .lineTo:
        try onLineTo(read(&bytecode), context)
      case .curveTo:
        try onCurveTo(read(&bytecode), context)
      case .quadCurveTo:
        try onQuadCurveTo(read(&bytecode), context)
      case .closePath:
        try onClosePath((), context)
      case .appendRectangle:
        try onAppendRectangle(read(&bytecode), context)
      case .appendRoundedRect:
        try onAppendRoundedRect((
          read(&bytecode),
          rx: read(&bytecode),
          ry: read(&bytecode)
        ), context)
      case .addEllipse:
        try onAddEllipse(read(&bytecode), context)
      case .addArc:
        try onAddArc((
          center: read(&bytecode),
          radius: read(&bytecode),
          startAngle: read(&bytecode),
          endAngle: read(&bytecode),
          clockwise: read(&bytecode)
        ), context)
      case .fill:
        try onFill((), context)
      case .fillWithRule:
        try onFillWithRule(read(&bytecode), context)
      case .stroke:
        try onStroke((), context)
      case .fillAndStroke:
        try onFillAndStroke((), context)
      case .drawPath:
        try onDrawPath(read(&bytecode), context)
      case .fillColor:
        try onFillColor(read(&bytecode), context)
      case .strokeColor:
        try onStrokeColor(read(&bytecode), context)
      case .fillAlpha:
        try onFillAlpha(read(&bytecode), context)
      case .strokeAlpha:
        try onStrokeAlpha(read(&bytecode), context)
      case .fillNone:
        try onFillNone((), context)
      case .strokeNone:
        try onStrokeNone((), context)
      case .lineWidth:
        try onLineWidth(read(&bytecode), context)
      case .lineCapStyle:
        try onLineCapStyle(read(&bytecode), context)
      case .lineJoinStyle:
        try onLineJoinStyle(read(&bytecode), context)
      case .miterLimit:
        try onMiterLimit(read(&bytecode), context)
      case .dash:
        try onDash(read(&bytecode), context)
      case .dashPhase:
        try onDashPhase(read(&bytecode), context)
      case .dashLengths:
        try onDashLengths(read(&bytecode), context)
      case .concatCTM:
        try onConcatCTM(read(&bytecode), context)
      case .globalAlpha:
        try onGlobalAlpha(read(&bytecode), context)
      case .setGlobalAlphaToFillAlpha:
        try onSetGlobalAlphaToFillAlpha((), context)
      case .blendMode:
        try onBlendMode(read(&bytecode), context)
      case .fillLinearGradient:
        try onFillLinearGradient((read(&bytecode), read(&bytecode)), context)
      case .fillRadialGradient:
        try onFillRadialGradient((read(&bytecode), read(&bytecode)), context)
      case .strokeLinearGradient:
        try onStrokeLinearGradient((read(&bytecode), read(&bytecode)), context)
      case .strokeRadialGradient:
        try onStrokeRadialGradient((read(&bytecode), read(&bytecode)), context)
      case .linearGradient:
        try onLinearGradient((read(&bytecode), read(&bytecode)), context)
      case .radialGradient:
        try onRadialGradient((read(&bytecode), read(&bytecode)), context)
      case .clip:
        try onClip((), context)
      case .clipWithRule:
        try onClipWithRule(read(&bytecode), context)
      case .clipToRect:
        try onClipToRect(read(&bytecode), context)
      case .beginTransparencyLayer:
        try onBeginTransparencyLayer((), context)
      case .endTransparencyLayer:
        try onEndTransparencyLayer((), context)
      case .shadow:
        try onShadow(read(&bytecode), context)
      case .subrouteWithId:
        try onSubrouteWithId(read(&bytecode), context)
      case .flatness:
        try onFlatness(read(&bytecode), context)
      case .fillEllipse:
        try onFillEllipse(read(&bytecode), context)
      case .colorRenderingIntent:
        try onColorRenderingIntent(read(&bytecode), context)
      case .fillRule:
        try onFillRule(read(&bytecode), context)
      case .replacePathWithStrokePath:
        try onReplacePathWithStrokePath((), context)
      case .lines:
        try onLines(read(&bytecode), context)
      }
    }
  }

  @inlinable @inline(__always)
  static func read<T: BytecodeDecodable>(_ bytecode: inout Bytecode) throws
    -> T {
    try T(bytecode: &bytecode)
  }
}
