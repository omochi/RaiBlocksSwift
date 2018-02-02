import Foundation

public struct NodeStats {
    public var peerAddCount: Int = 0
    public var peerRemoveCount: Int = 0
    public var peerCount: Int = 0
    public var keepaliveSendCount: Int = 0
    public var keepaliveReceiveCount: Int = 0

    public mutating func clear() {
        self = NodeStats()
    }
    
}

extension NodeStats : CustomStringConvertible {
    public var description: String {
        var fields: [String] = []
        fields.append("peer=\(peerAddCount)/\(peerRemoveCount)/\(peerCount)")
        fields.append("keepalive=\(keepaliveReceiveCount)/\(keepaliveSendCount)")
        return "NodeStats(\(fields.joined(separator: ", ")))"
    }
}
