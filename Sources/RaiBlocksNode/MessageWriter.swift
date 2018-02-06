import Foundation
import RaiBlocksBasic

public class MessageWriter {
    public init() {
    }
    
    public func write(message: Message, network: Network) -> Data {
        var header = Message.Header(kind: message.kind, network: network)
        header.blockKind = message.blockKind
        let writer = DataWriter()
        writer.write(header)
        writer.write(message)
        return writer.data
    }
}
