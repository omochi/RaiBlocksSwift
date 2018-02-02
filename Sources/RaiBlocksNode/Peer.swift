import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class Peer {
    public let endPoint: EndPoint

    public var lastAliveTime: Date
    public var lastReceivedTime: Date?
    public var lastSentTime: Date?
    
    public init(endPoint: EndPoint, now: Date) {
        self.endPoint = endPoint
        self.lastAliveTime = now
    }
}
