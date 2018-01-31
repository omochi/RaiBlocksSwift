import RaiBlocksSocket
import RaiBlocksBasic

import Foundation

public class Node {
    public convenience init(environment: Environment,
                            queue: DispatchQueue) throws {
        let impl = try Impl(environment: environment,
                            queue: queue)
        self.init(impl: impl)
    }
    
    deinit {
        terminate()
    }
    
    public func terminate() {
        impl.terminate()
    }
    
    private class Impl {
        public init(environment: Environment,
                    queue: DispatchQueue) throws
        {
            self.queue = queue
            self.environment = environment
            
            let logger = Logger()
            self.logger = TaggedLogger(tag: "Node", logger: logger)
            
            self.messageReceiver = try MessageReceiver(queue: queue)
        }
        
        public func terminate() {
            messageReceiver.terminate()
        }
        
        private func receive() {

        }

        private let queue: DispatchQueue
        private let environment: Environment
        private let logger: TaggedLogger
     
        private let messageReceiver: MessageReceiver
    }
    
    private class MessageReceiver {
        public init(queue: DispatchQueue,
                    logger: Logger) throws {
            self.queue = queue
            
            let socket = UDPSocket(callbackQueue: queue)
            self.socket = socket
            
            try socket.open(protocolFamily: .ipv4)
            
            receive()
        }
        
        public func terminate() {
            receiveRestartTimer?.cancel()
            receiveRestartTimer = nil
            
            socket.close()
        }
        
        private func receive() {
            socket.receive(size: 2048,
                           successHandler: { (data, endPoint) in
                            
                            
                            
                            self.receive()
            },
                           errorHandler: { (error) in
                            // TODO: Logger
//                            self.logError(message: "socket.receive: \(error)")
                            self.receiveRestartTimer = makeTimer(delay: 1.0, queue: self.queue) {
                                self.receive()
                            }
            })
        }
        
        private let queue: DispatchQueue
        private let logger: TaggedLogger
        private let socket: UDPSocket
        private var receiveRestartTimer: DispatchSourceTimer?
    }

    private init(impl: Impl) {
        self.impl = impl
    }
    
    private let impl: Impl

}
