import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class MessageReceiver {
    public typealias Handler = (EndPoint, Message.Header, Message, () -> Void) -> Void
    
    public init(queue: DispatchQueue,
                logger: Logger) {
        self.queue = queue
        self.messageReader = MessageReader()
        self.logger = Logger(config: logger.config, tag: "MessageReceiver")
        
        let socket = UDPSocket(callbackQueue: queue)
        self.socket = socket
    }
    
    public func terminate() {
        logger.trace("terminate")
        
        receiveRestartTimer?.cancel()
        receiveRestartTimer = nil
        
        socket.close()
    }
    
    public func start(handler: @escaping Handler) throws {
        self.handler = handler
        
        try socket.open(protocolFamily: .ipv4)
        
        receive()
    }
    
    private func receive() {
        logger.trace("receive")
        
        func next() {
            queue.async {
                if self.socket.state == .closed {
                    self.logger.trace("receive.exit: socket closed")
                    return
                }
                
                self.receive()
            }
        }
        
        socket.receive(size: 2048,
                       successHandler: { (data, endPoint) in
                        do {
                            let (header, message) = try self.messageReader.read(data: data)
                            self.logger.debug("message: header=[\(header)], message=[\(message)]")
                            
                            self.handler!(endPoint, header, message, next)
                        } catch let error {
                            self.logger.debug("message read error: \(error)")
                            next()
                        }
        },
                       errorHandler: { (error) in
                        self.logger.error("socket.receive error: \(error)")
                        self.receiveRestartTimer = makeTimer(delay: 1.0, queue: self.queue) {
                            next()
                        }
        })
    }
    
    private let queue: DispatchQueue
    private let messageReader: MessageReader
    private let logger: Logger
    private let socket: UDPSocket
    private var receiveRestartTimer: DispatchSourceTimer?
    
    private var handler: Handler?
}
