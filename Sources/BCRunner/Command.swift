import Foundation

enum Command: UInt8 {
    case foo = 0 //(void)
    case bar = 1 //(float32 arg)
    case declSubroute = 2 //(uint8 id, uint16 size)
    case runSubroute = 3 //(uint8 id)
    case move = 4 //(float32 x, float32 y)
}
