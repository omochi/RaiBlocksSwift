import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class NodeImpl {
    public init(environment: Environment,
                logger: Logger,
                queue: DispatchQueue)
    {
        self.environment = environment
        self.queue = queue
        self.logger = Logger(config: logger.config, tag: "Node")
        self.terminated = false
        
        logger.debug("dataDir: \(environment.dataDir)")
        logger.debug("tempDir: \(environment.tempDir)")
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
        
        startNameResolve()
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
        
        nameResolveTask?.terminate()
        nameResolveTask = nil
        
        nameResolveRestartTimer?.cancel()
        nameResolveRestartTimer = nil
    }
    
    private func restartAfterWait() {
        if restartTimer != nil { return }
        
        reset()
        
        let wait: TimeInterval = 5.0
        logger.debug("restart: wait=\(wait)")

        restartTimer = makeTimer(delay: wait, queue: queue) {
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
    
    private func startNameResolve() {
        let hostname = "rai.raiblocks.net"
        logger.debug("nameResolve: \(hostname)")
        
        var task: NameResolveTask!
        
        task = nameResolve(protocolFamily: .ipv4,
                               hostname: hostname,
                               callbackQueue: queue,
                               successHandler: { (endPoints) in
                                guard task === self.nameResolveTask else { return }
                                
                                self.logger.debug("\(endPoints)")
                                self.resetNameResolve()
                                
                                guard var endPoint = endPoints.getRandom() else {
                                    self.logger.error("nameResolve empty")
                                    self.restartNameResolveAfterWait()
                                    return
                                }
                                
                                endPoint.port = 7075
                                
                                let message = Message.keepalive(.init(endPoints: []))
                                self.messageSender?.send(endPoints: [endPoint], message: message)
        },
                               errorHandler: { error in
                                guard task === self.nameResolveTask else { return }
                                
                                self.logger.error("nameResolve error: \(error)")
                                self.restartNameResolveAfterWait()
                                
        })
        self.nameResolveTask = task
    }
    
    private func resetNameResolve() {
        nameResolveTask?.terminate()
        nameResolveTask = nil
        
        nameResolveRestartTimer?.cancel()
        nameResolveRestartTimer = nil
    }
    
    private func restartNameResolveAfterWait() {
        if nameResolveRestartTimer != nil { return }
        
        resetNameResolve()
        
        let wait: TimeInterval = 5.0
        logger.debug("restartNameResolve: wait=\(wait)")
        
        nameResolveRestartTimer = makeTimer(delay: wait, queue: queue) {
            if self.terminated { return }
            self.nameResolveRestartTimer = nil
            
            self.startNameResolve()
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
    
    private var terminated: Bool
    
    private var nameResolveTask: NameResolveTask?
    private var messageReceiver: MessageReceiver?
    private var messageSender: MessageSender?
    private var socket: UDPSocket?
    
    private var restartTimer: DispatchSourceTimer?
    private var nameResolveRestartTimer: DispatchSourceTimer?
}


