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
        
        self.peers = []
        
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
                                            self.restartAfterWait()
        })
        
        messageSender = MessageSender(queue: queue, logger: logger, socket: socket,
                                      errorHandler: { _ in
                                        self.restartAfterWait()
        })
        
        startInitialPeerNameResolve()
    }
    
    private func reset() {
        logger.trace("reset")
        
        restartTimer?.cancel()
        restartTimer = nil
        
        messageReceiver?.terminate()
        messageReceiver = nil
        
        messageSender?.terminate()
        messageSender = nil
        
        socket?.close()
        socket = nil

        initialPeerResolver?.terminate()
        initialPeerResolver = nil
        
        self.peers.removeAll()
    }
    
    private func restartAfterWait() {
        if restartTimer != nil { return }
        
        reset()
        
        logger.debug("restart")

        restartTimer = makeTimer(delay: config.recoveryInterval, queue: queue) {
            if self.terminated { return }
            
            self.restartTimer = nil
            
            do {
                try self.start()
            } catch let error {
                self.logger.error("start error: \(error)")
                self.restartAfterWait()
            }
        }
    }
    
    private func startInitialPeerNameResolve() {
        precondition(initialPeerResolver == nil)
        
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
    
    private var restartTimer: DispatchSourceTimer?
    
    private var initialPeerResolver: InitialPeerResolver?
    private var peers: [Peer]
}


