import Foundation

enum Command: UInt8 {
    case declSubroute = 1 //(uint8 id, uint16 size)
    case runSubroute = 2 //(uint8 id)
    case move = 3 //(float32 x, float32 y)
}
