import Foundation
import RaiBlocksBasic

public class MessageWriter {
    public init() {
    }
    
    public func write<X: MessageProtocol>(message: X) -> Data {
        var header = Message.Header(kind: X.kind)
        header.blockKind = message.blockKind
        let writer = DataWriter()
        writer.write(header)
        writer.write(message)
        return writer.data
    }
    
    public func write(message: Message) -> Data {
        switch message {
        case .keepalive(let m): return write(message: m)
        case .publish(let m): return write(message: m)
        case .confirmRequest(let m): return write(message: m)
        case .accountRequest(let m): return write(message: m)
        }
    }
}
