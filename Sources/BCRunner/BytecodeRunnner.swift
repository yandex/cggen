import CoreGraphics
import Foundation

import BCCommon

private class BytecodeRunner {
  struct State {
    var position: UnsafePointer<UInt8>
    var remaining: Int
  }

  class Commons {
    var subroutes: [UInt8: State] = [:]
    let context: CGContext
    init(_ context: CGContext) {
      self.context = context
    }
  }

  var currentState: State
  let commons: Commons
  init(_ state: State, _ commons: Commons) {
    currentState = state
    self.commons = commons
  }

  func advance(_ count: Int) {
    currentState.position += count
    currentState.remaining -= count
  }

  func read<T: FixedWidthInteger>(_: T.Type = T.self) -> T {
    let size = MemoryLayout<T>.size
    precondition(size >= currentState.remaining)
    var ret: T = 0
    memcpy(&ret, currentState.position, size)
    advance(size)
    return T(littleEndian: ret)
  }

  func readCGFloat() -> CGFloat {
    .init(Float(bitPattern: read()))
  }

  func run() {
    let context = commons.context
    while currentState.remaining > 0 {
      let command = Command(rawValue: read())
      switch command {
      case .declSubroute:
        let id = read(UInt8.self)
        let sz = Int(read(UInt16.self))
        let subroute = State(
          position: currentState.position,
          remaining: sz
        )
        commons.subroutes[id] = subroute
        advance(sz)
      case .runSubroute:
        let id = read(UInt8.self)
        let subroute = commons.subroutes[id]!
        BytecodeRunner(subroute, commons).run()
      case .move:
        let x = readCGFloat()
        let y = readCGFloat()
        let point = CGPoint(x: x, y: y)
        context.move(to: point)
      default:
        print("unknown")
      }
    }
  }
}

@_cdecl("runBytecode") func runBytecode(
  _ context: CGContext,
  _ start: UnsafePointer<UInt8>,
  _ len: Int
) {
  let cs = CGColorSpaceCreateDeviceRGB()
  context.setFillColorSpace(cs)
  context.setStrokeColorSpace(cs)
  let state = BytecodeRunner.State(position: start, remaining: len)
  let commons = BytecodeRunner.Commons(context)
  BytecodeRunner(state, commons).run()
}
