import Foundation
import CoreGraphics

class BytecodeRunner {
    struct State {
        var position: UnsafePointer<UInt8>
        var remaining: Int
    }
    
    class Commons {
        private var subroutes: Array<State?> = []
        var context: CGContext
        init(_ context: CGContext) {
            self.context = context
        }
        func addSubroutine(_ id: Int, _ subroute: State) {
            let sz = subroutes.count
            if sz <= id {
                subroutes.append(contentsOf: Array(repeating: nil, count: id - sz + 1))
            }
            subroutes[id] = subroute
        }
        func getSubroutine(_ id : Int) -> State {
            return subroutes[id]!
        }
    }

    var currentState: State
    var commons: Commons
    init (_ state: State, _ commons: Commons) {
        currentState = state
        self.commons = commons
    }
    
    func advance (_ count: Int) {
        currentState.position += count
        currentState.remaining -= count
    }
    
    func readUInt8() -> UInt8 {
        let ret = currentState.position.pointee
        advance(1)
        return ret
    }
    
    func readUint16() -> UInt16 {
        var ret: UInt16 = 0
        memcpy(&ret, currentState.position, 2)
        advance(2)
        return ret
    }
    
    func readFloat32() -> Float32 {
        var ret: Float32 = 0
        memcpy(&ret, currentState.position, 4)
        advance(4)
        return ret
    }
    
    func run() {
        while currentState.remaining > 0 {
            let command = Command.init(rawValue: readUInt8())!
            switch command {
            case .foo:
                print("foo")
            case .bar:
                let arg = readFloat32()
                print("bar", arg)
            case .declSubroute:
                let id = Int(readUInt8())
                let sz = Int(readUint16())
                let subroutine = State(position: currentState.position, remaining: sz)
                commons.addSubroutine(id, subroutine)
                advance(sz)
            case .runSubroute:
                let id = Int(readUInt8())
                let subroutine = commons.getSubroutine(id)
                BytecodeRunner(subroutine, commons).run()
            case .move:
                let x = CGFloat(readFloat32())
                let y = CGFloat(readFloat32())
                let point = CGPoint(x:x, y:y)
                commons.context.move(to: point)
            default:
                print("unknown")
            }
        }
    }
}

@_cdecl("runBytecode") func runBytecode(_ context: CGContext, _ start: UnsafePointer<UInt8>, _ len: Int) {
    let cs = CGColorSpaceCreateDeviceRGB()
    context.setFillColorSpace(cs)
    context.setStrokeColorSpace(cs)
    let state = BytecodeRunner.State(position: start, remaining: len)
    let commons = BytecodeRunner.Commons(context)
    BytecodeRunner(state, commons).run()
}

