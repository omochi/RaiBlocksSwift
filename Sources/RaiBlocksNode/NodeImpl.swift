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
        
        self.stats = NodeStats()
        
        logger.info("environment: \(environment)")
        logger.info("config: \(config)")
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
        
        self.peerManager = buildPeerManager(socket: socket)

        refresh()
    }
    
    private func reset() {
        logger.trace("reset")
        
        peerManager?.terminate()
        peerManager = nil
        
        stats.clear()
        
        refreshTimer?.cancel()
        refreshTimer = nil

        socket?.close()
        socket = nil
        
        recoveryTimer?.cancel()
        recoveryTimer = nil
    }
    
    private func startRecovery() {
        if recoveryTimer != nil { return }
        
        reset()
        
        logger.debug("schedule recovery")

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

        peerManager!.refresh(now: now)
        
        stats.activePeerCount = peerManager!.activePeers.count
        stats.peerCount = peerManager!.peers.count
        
        stats.lines.forEach {
             logger.info($0)
        }
        stats.clear()
    
        scheduleRefresh()
    }
    
    private func buildPeerManager(socket: UDPSocket) -> PeerManager {
        let pm = PeerManager(queue: queue, logger: logger,
                             config: config, socket: socket)
        pm.messageHandler = {
            self.handleMessage(peer: $0, header: $1, message: $2, now: $3) }
        pm.errorHandler = { _ in
            self.startRecovery()
        }
        pm.notifyAddHandler = { (peer, now) in
            self.stats.peerAddCount += 1 }
        pm.notifyRemoveHandler = { (peer, now) in
            self.stats.peerRemoveCount += 1 }
        pm.notifySendMessageHandler = { (peers, message, now) in
            switch message.kind {
            case .keepalive:
                self.stats.keepaliveSendCount += peers.count
            default:
                // TODO
                break
            }
        }
        
        return pm
    }
    
    private func handleMessage(peer: Peer,
                               header: Message.Header,
                               message: Message,
                               now: Date)
    {
        switch message {
        case .keepalive(let m):
            stats.keepaliveReceiveCount += 1
            peerManager!.handleNotifiedEndPoints(endPoints: m.endPoints, now: now)
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
    
    private var socket: UDPSocket?
    private var peerManager: PeerManager?
    private var stats: NodeStats
    private var refreshTimer: DispatchSourceTimer?
    
    private var recoveryTimer: DispatchSourceTimer?
}


