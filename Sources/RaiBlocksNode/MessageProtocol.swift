import Foundation
import RaiBlocksBasic

public protocol MessageProtocol : CustomStringConvertible, DataWritable {
    var blockKind: Block.Kind? { get }
    
    static var kind: Message.Kind { get }
}
