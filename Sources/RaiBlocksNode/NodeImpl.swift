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
        
        self.peers = [:]
        
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
                                          handler: {
                                            self.handleMessage(endPoint: $0, header: $1, message: $2, next: $3)
        },
                                          errorHandler: { _ in
                                            self.startRecovery()
        })
        
        messageSender = MessageSender(queue: queue, logger: logger, socket: socket,
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
        
        self.peers.removeAll()
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
            
            self.refreshTimer = nil
            
            self.refresh()
        }
    }
    
    private func refresh() {
        logger.trace("refresh")
        
        let now = Date()
        removeOfflinePeers(now: now)
        
        if peers.isEmpty {
            startInitialPeerNameResolve()
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
                                                    let endPoints: [EndPoint] = endPoints.map { endPoint in
                                                        var endPoint: EndPoint = endPoint
                                                        endPoint.port = self.config.peerPort
                                                        return endPoint
                                                    }
                                                    self.onFoundPeerEndPoints(endPoints)
        },
                                                  completeHandler: {
                                             self.initialPeerResolver = nil
        })
    }
    
    private func onFoundPeerEndPoints(_ endPoints: [EndPoint]) {
        let oldNum = peers.count
        let now = Date.init()
        for endPoint in endPoints {
            updatePeerLastSeenTime(endPoint: endPoint, time: now)
        }
        
        let addNum = peers.count - oldNum
        if addNum > 0 {
            logger.info("found new \(addNum) peers: \(peers.count)")
        }
    }
    
    private func updatePeerLastSeenTime(endPoint: EndPoint, time: Date) {
        let peer = { () -> Peer in
            if var peer = peers[endPoint] {
                peer.lastSeenTime = time
                return peer
            } else {
                return Peer(endPoint: endPoint,
                            lastSeenTime: time)
            }
        }()
        peers[endPoint] = peer
    }
    
    private func removeOfflinePeers(now: Date) {
        let oldNum = peers.count
        for (endPoint, peer) in (peers.map { ($0, $1) }) {
            if peer.lastSeenTime + config.offlineInterval <= now {
                peers.removeValue(forKey: endPoint)
            }
        }
        let removeNum = oldNum - peers.count
        if removeNum > 0 {
            logger.info("lost \(removeNum) peers: \(peers.count)")
        }
    }
    
    private func handleMessage(endPoint: EndPoint,
                               header: Message.Header,
                               message: Message,
                               next: @escaping () -> Void)
    {
        next()
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
    private var peers: [EndPoint: Peer]
    
    private var refreshTimer: DispatchSourceTimer?
}


