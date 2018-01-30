import Foundation
import RaiBlocksBasic

public class MessageReader {
    public func read(data: Data) throws -> Any {
        let reader = DataReader(data: data)
        let header = try Message.Header(from: reader)
        switch header.kind {
        case .invalid, .notAKind:
            throw GenericError(message: "invalid message kind: \(header.kind)")
        case .keepalive:
            return try Message.Keepalive(from: reader)
        case .publish:
            guard let blockKind = header.blockKind else  {
                throw GenericError(message: "block kind for publish is nil")
            }
            return try Message.Publish(from: reader, blockKind: blockKind)
        case .confirmReq:
            fatalError("TODO")
        case .confirmAck:
            fatalError("TODO")
        case .bulkPull:
            fatalError("TODO")
        case .bulkPush:
            fatalError("TODO")
        case .accountRequest:
             fatalError("TODO")
        }
    }
}
