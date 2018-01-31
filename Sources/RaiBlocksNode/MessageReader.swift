import Foundation
import RaiBlocksBasic

public class MessageReader {
    public func read(data: Data) throws -> (Message.Header, Message?) {
        let reader = DataReader(data: data)
        let header = try Message.Header(from: reader)
        let message: Message?
        switch header.kind {
        case .invalid, .notAKind:
            throw GenericError(message: "invalid message kind: \(header.kind)")
        case .keepalive:
            message = .keepalive(try Message.Keepalive(from: reader))
        case .publish:
            let blockKind = try header.blockKind.unwrap(or: "block kind for publish is none")
            message = .publish(try Message.Publish(from: reader, blockKind: blockKind))
        case .confirmRequest:
            let blockKind = try header.blockKind.unwrap(or: "block kind for confirmRequest is none")
            message = .confirmRequest(try Message.ConfirmRequest(from: reader, blockKind: blockKind))
        case .confirmAck, .bulkPull, .bulkPush:
            print("[TODO] unsupported message: \(header.kind)")
            message = nil
        case .accountRequest:
            message = .accountRequest(try Message.AccountRequest(from: reader))
        }
        return (header, message)
    }
}
