import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class NodeImpl {
    public init(environment: Environment,
                logger: Logger,
                config: Node.Config,
                queue: DispatchQueue)
    {
        self.environment = environment
        self.queue = queue
        self.logger = Logger(config: logger.config, tag: "Node")
        self.config = config
        self.terminated = false
        
        self.peerMap = [:]
        self.stats = NodeStats()
        
        logger.debug("environment: \(environment)")
        logger.debug("config: \(config)")
    }
    
    public func terminate() {
        logger.trace("terminate")
        reset()
        terminated = true
    }

    public func start() throws {
        let socket = UDPSocket(callbackQueue: queue)
        self.socket = socket
        
        try socket.open(protocolFamily: .ipv4)
        
        messageReceiver = MessageReceiver(queue: queue, logger: logger, socket: socket,
                                          handler: { (endPoint, header, message) in
                                            self.handleMessage(endPoint: endPoint,
                                                               header: header,
                                                               message: message)
        },
                                          errorHandler: { _ in
                                            self.startRecovery()
        })
        
        messageSender = MessageSender(queue: queue, logger: logger, socket: socket,
                                      bufferSize: config.sendingBufferSize,
                                      errorHandler: { _ in
                                        self.startRecovery()
        })
        
        refresh()
    }
    
    private func reset() {
        logger.trace("reset")
        
        recoveryTimer?.cancel()
        recoveryTimer = nil
        
        messageReceiver?.terminate()
        messageReceiver = nil
        
        messageSender?.terminate()
        messageSender = nil
        
        socket?.close()
        socket = nil
        
        refreshTimer?.cancel()
        refreshTimer = nil

        initialPeerResolver?.terminate()
        initialPeerResolver = nil
        
        peerMap.removeAll()
        
        stats.clear()
    }
    
    private func startRecovery() {
        if recoveryTimer != nil { return }
        
        reset()
        
        logger.debug("recovery")

        recoveryTimer = makeTimer(delay: config.recoveryInterval, queue: queue) {
            if self.terminated { return }
            
            self.recoveryTimer = nil
            
            do {
                try self.start()
            } catch let error {
                self.logger.error("start error: \(error)")
                self.startRecovery()
            }
        }
    }
    
    private func scheduleRefresh() {
        refreshTimer?.cancel()
        
        refreshTimer = makeTimer(delay: config.refreshInterval, queue: queue) {
            if self.terminated { return }
            self.refresh()
        }
    }
    
    private func refresh() {
        logger.trace("refresh")
        
        refreshTimer?.cancel()
        refreshTimer = nil
        
        let now = Date()
        removeOfflinePeers(now: now)
        
        stats.activePeerCount = activePeers.count
        stats.peerCount = peers.count
        
        stats.lines.forEach {
             logger.info($0)
        }
       
        stats.clear()
        
        if peerMap.isEmpty {
            startInitialPeerNameResolve()
        } else {
            sendKeepalive(now: now)
        }

        scheduleRefresh()
    }
    
    private func startInitialPeerNameResolve() {
        initialPeerResolver?.terminate()
        
        initialPeerResolver = InitialPeerResolver(logger: logger,
                                                  queue: queue,
                                                  hostnames: config.initialPeerHostnames,
                                                  recoveryInterval: config.recoveryInterval,
                                                  endPointsHandler: { endPoints in
                                                    
                                                    let endPoints: [IPv6.EndPoint] = endPoints.map { endPoint in
                                                        var endPoint: IPv6.EndPoint = endPoint
                                                        endPoint.port = self.config.peerPort
                                                        return endPoint
                                                    }
                                                    
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
    
    private func getOrAddPeerIfValidEndPoint(endPoint v6ep: IPv6.EndPoint, now: Date) -> Peer? {
        if !isValidEndPoint(endPoint: v6ep) {
            return nil
        }
        
        let endPoint: EndPoint
        switch socket!.protocolFamily! {
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
        
        return addPeer(endPoint: endPoint, now: now)
    }
    
    private func addPeer(endPoint: EndPoint, now: Date) -> Peer {
        precondition(peerMap[endPoint] == nil)
        
        let peer = Peer(endPoint: endPoint, now: now)
        peerMap[endPoint] = peer
        
        stats.peerAddCount += 1
        
        return peer
    }
    
    private func updatePeerReceived(peer: Peer, now: Date) {
        peer.lastReceivedTime = now
        peer.lastAliveTime = now
    }
    
    private func removeOfflinePeers(now: Date) {
        for (endPoint, peer) in (peerMap.map { ($0, $1) }) {
            if peer.lastAliveTime + config.offlineInterval <= now {
                peerMap.removeValue(forKey: endPoint)
                stats.peerRemoveCount += 1
            }
        }
    }
    
    private func sendKeepalive(now: Date) {
        let peers = self.activePeers.filter {
            self.shouldSendKeepalive(peer: $0, now: now)
        }
        
        peers.forEach {
            self.sendKeepalive(peer: $0, now: now)
        }
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

    private func sendKeepalive(peer: Peer, now: Date) {
        let endPoints = activePeers
            .map { $0.endPoint }
            .getRandomElements(num: 8)
        
        let message = Message.Keepalive(endPoints: endPoints.map { $0.toV6() })
        
        stats.keepaliveSendCount += 1
        
        sendMessage(peers: [peer], message: .keepalive(message), now: now)
    }
    
    private func sendMessage(peers: [Peer],
                             message: Message,
                             now: Date)
    {
        peers.forEach { peer in
            peer.lastSentTime = now
        }
        
        messageSender!.send(endPoints: peers.map { $0.endPoint }, message: message)
    }
    
    private func handleNotifiedEndPoints(endPoints: [IPv6.EndPoint],
                                         now: Date)
    {
        let peers = endPoints
            .flatMap {
                self.getOrAddPeerIfValidEndPoint(endPoint: $0, now: now)
            }
            .filter {
                self.shouldSendKeepalive(peer: $0, now: now)
        }

        peers.forEach {
            self.sendKeepalive(peer: $0, now: now)
        }
    }
    
    private func handleMessage(endPoint: EndPoint,
                               header: Message.Header,
                               message: Message)
    {
        let now = Date()
        guard let peer = getOrAddPeerIfValidEndPoint(endPoint: endPoint.toV6(), now: now) else {
            logger.warn("message received from invalid end point: \(endPoint), \(message)")
            return
        }
        updatePeerReceived(peer: peer, now: now)
        handleMessage(peer: peer, header: header, message: message, now: now)
    }
    
    private func handleMessage(peer: Peer,
                               header: Message.Header,
                               message: Message,
                               now: Date)
    {
        switch message {
        case .keepalive(let m):
            stats.keepaliveReceiveCount += 1
            self.handleNotifiedEndPoints(endPoints: m.endPoints, now: now)
        case .publish(let m):
            logger.debug("TODO: unimplemented handler: \(m)")
        case .confirmRequest(let m):
            logger.debug("TODO: unimplemented handler: \(m)")
        case .accountRequest(let m):
            logger.debug("TODO: unimplemented handler: \(m)")
        }
    }
    
    private let queue: DispatchQueue
    private let environment: Environment
    private let logger: Logger
    private let config: Node.Config
    
    private var terminated: Bool
    
    private var messageReceiver: MessageReceiver?
    private var messageSender: MessageSender?
    private var socket: UDPSocket?
    
    private var recoveryTimer: DispatchSourceTimer?
    
    private var initialPeerResolver: InitialPeerResolver?
    private var peerMap: [EndPoint: Peer]
    private var peers: [Peer] {
        return Array(peerMap.values)
    }
    private var activePeers: [Peer] {
        return peers.filter { $0.lastReceivedTime != nil }
    }
    
    private var stats: NodeStats
    
    private var refreshTimer: DispatchSourceTimer?
}


