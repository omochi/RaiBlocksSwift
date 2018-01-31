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
}
