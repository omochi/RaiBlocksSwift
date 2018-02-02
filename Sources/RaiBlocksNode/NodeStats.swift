import Foundation

public struct NodeStats {
    public var peerAddCount: Int = 0
    public var peerRemoveCount: Int = 0
    public var activePeerCount: Int = 0
    public var peerCount: Int = 0
    public var keepaliveSendCount: Int = 0
    public var keepaliveReceiveCount: Int = 0

    public mutating func clear() {
        self = NodeStats()
    }
    
}

extension NodeStats {
    public var lines: [String] {
        var lines: [String] = []
        lines.append("peer: add=\(peerAddCount), rem=\(peerRemoveCount) => active=\(activePeerCount) / all=\(peerCount)")
        lines.append("keepalive: recv=\(keepaliveReceiveCount), send=\(keepaliveSendCount)")
        return lines
    }
}
