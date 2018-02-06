import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class PeerManager {
    public init(queue: DispatchQueue,
                config: Node.Config,
                socket: UDPSocket)
    {
        var sself: PeerManager!
        
        self.queue = queue
        self.config = config
        self.logger = Logger(config: config.loggerConfig, tag: "PeerManager")

        self.socket = socket

        self.receiver = MessageReceiver(queue: queue,
                                        loggerConfig: config.loggerConfig,
                                        network: config.network,
                                        socket: socket,
                                        handler: { (endPoint, header, message) in
                                            sself.handleMessage(endPoint: endPoint,
                                                                header: header,
                                                                message: message)
        },
                                        errorHandler: { error in
                                            sself.errorHandler?(error)
        })
        
        self.sender = MessageSender(queue: queue,
                                    loggerConfig: config.loggerConfig,
                                    network: config.network,
                                    socket: socket,
                                    bufferSize: config.sendingBufferSize,
                                    errorHandler: { error in
                                        sself.errorHandler?(error)
        })
        
        self.peerMap = [:]
        
        sself = self
    }
    
    deinit {
        terminate()
    }
    
    public func terminate() {
        initialPeerResolver?.terminate()
        initialPeerResolver = nil
        
        receiver.terminate()
        sender.terminate()
    }
    
    public var peers: [Peer] {
        return Array(peerMap.values)
    }
    
    public var activePeers: [Peer] {
        return peers.filter { $0.lastReceivedTime != nil }
    }
    
    public var messageHandler: ((Peer, Message.Header, Message, Date) -> Void)?
    public var errorHandler: ((Error) -> Void)?
    public var notifyAddHandler: ((Peer, Date) -> Void)?
    public var notifyRemoveHandler: ((Peer, Date) -> Void)?
    public var notifySendMessageHandler: (([Peer], Message, Date) -> Void)?

    public func refresh(now: Date) {
        removeOfflinePeers(now: now)
        
        if peerMap.isEmpty {
            startInitialPeerNameResolve()
        } else {
            sendKeepalive(now: now)
        }
    }
    
    public func handleNotifiedEndPoints(endPoints: [IPv6.EndPoint], now: Date) {
        let peers = endPoints
            .flatMap {
                getOrAddIfValidEndPoint(endPoint: $0, now: now)
            }
            .filter {
                shouldSendKeepalive(peer: $0, now: now)
        }
        
        peers.forEach {
            sendKeepalive(peer: $0, now: now)
        }
    }
    
    private func removeOfflinePeers(now: Date) {
        peers.forEach { peer in
            if peer.lastAliveTime + config.offlineInterval <= now {
                peerMap.removeValue(forKey: peer.endPoint)
                notifyRemoveHandler?(peer, now)
            }
        }
    }
    
    private func startInitialPeerNameResolve() {
        initialPeerResolver?.terminate()
        
        initialPeerResolver = InitialPeerResolver(queue: queue,
                                                  loggerConfig: config.loggerConfig,
                                                  hostnames: config.network.initialPeerHostnames,
                                                  peerPort: config.network.peerPort,
                                                  recoveryInterval: 10,
                                                  endPointsHandler: { endPoints in
                                                    let now = Date()
                                                    self.handleNotifiedEndPoints(endPoints: endPoints, now: now)
        },
                                                  completeHandler: {
                                                    self.initialPeerResolver = nil
        })
    }
    
    private func isValidEndPoint(endPoint: IPv6.EndPoint) -> Bool {
        if let ad = endPoint.mappedV4?.address {
            if IPv4.Address.loopbackRange.contains(ad) {
                return false
            }
            if IPv4.Address.multicastRange.contains(ad) {
                return false
            }
        }
        
        let ad = endPoint.address
        
        if ad == .loopback {
            return false
        }
        if IPv6.Address.multicastRange.contains(ad) {
            return false
        }
        
        return true
    }
    
    private func getOrAddIfValidEndPoint(endPoint v6ep: IPv6.EndPoint, now: Date) -> Peer? {
        if !isValidEndPoint(endPoint: v6ep) {
            return nil
        }
        
        let endPoint: EndPoint
        switch socket.protocolFamily! {
        case .ipv4:
            if let v4 = v6ep.mappedV4 {
                endPoint = .ipv4(v4)
            } else {
                return nil
            }
        case .ipv6:
            endPoint = .ipv6(v6ep)
        }
        
        if let peer = peerMap[endPoint] {
            return peer
        }
        
        return add(endPoint: endPoint, now: now)
    }
    
    private func add(endPoint: EndPoint, now: Date) -> Peer {
        precondition(peerMap[endPoint] == nil)
        
        let peer = Peer(endPoint: endPoint, now: now)
        peerMap[endPoint] = peer
        
        notifyAddHandler?(peer, now)

        return peer
    }
    
    private func updateReceivedTime(peer: Peer, now: Date) {
        peer.lastReceivedTime = now
        peer.lastAliveTime = now
    }
    
    private func shouldSendKeepalive(peer: Peer, now: Date) -> Bool {
        if let lastReceivedTime = peer.lastReceivedTime {
            if now <= lastReceivedTime + config.refreshInterval {
                return false
            }
        }
        
        if let lastSentTime = peer.lastSentTime {
            if now <= lastSentTime + config.refreshInterval {
                return false
            }
        }
        
        return true
    }
    
    private func sendKeepalive(now: Date) {
        let peers = activePeers.filter {
            shouldSendKeepalive(peer: $0, now: now)
        }
        
        peers.forEach {
            sendKeepalive(peer: $0, now: now)
        }
    }
    
    private func sendKeepalive(peer: Peer, now: Date) {
        let endPoints = activePeers
            .map { $0.endPoint }
            .getRandomElements(num: 8)
        
        let message = Message.Keepalive(endPoints: endPoints.map { $0.toV6() })
        
        sendMessage(peers: [peer], message: .keepalive(message), now: now)
    }

    private func sendMessage(peers: [Peer],
                             message: Message,
                             now: Date)
    {
        peers.forEach { peer in
            peer.lastSentTime = now
        }
        
        notifySendMessageHandler?(peers, message, now)
        
        sender.send(endPoints: peers.map { $0.endPoint }, message: message)
    }
    
    private func handleMessage(endPoint: EndPoint,
                               header: Message.Header,
                               message: Message)
    {
        let now = Date()
        guard let peer = getOrAddIfValidEndPoint(endPoint: endPoint.toV6(), now: now) else {
            logger.warn("message received from invalid end point: \(endPoint), \(message)")
            return
        }
        updateReceivedTime(peer: peer, now: now)
        messageHandler?(peer, header, message, now)
    }
    
    private let queue: DispatchQueue
    private let config: Node.Config
    private let logger: Logger
    private let socket: UDPSocket
    private let receiver: MessageReceiver
    private let sender: MessageSender
    
    private var initialPeerResolver: InitialPeerResolver?
    private var peerMap: [EndPoint: Peer]
}
