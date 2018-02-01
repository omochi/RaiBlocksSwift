import RaiBlocksSocket
import RaiBlocksBasic

import Foundation

public class Node {
    public convenience init(environment: Environment,
                            logger: Logger,
                            queue: DispatchQueue) {
        self.init(impl: Impl(environment: environment,
                             logger: logger,
                             queue: queue))
    }
    
    deinit {
        terminate()
    }
    
    public func terminate() {
        impl.terminate()
    }
    
    public func start() throws {
        try impl.start()
    }
    
    private class Impl {
        public init(environment: Environment,
                    logger: Logger,
                    queue: DispatchQueue)
        {
            self.environment = environment
            self.queue = queue
            self.logger = Logger(config: logger.config, tag: "Node")
            self.messageReceiver = MessageReceiver(queue: queue, logger: logger)
            
            logger.debug("dataDir: \(environment.dataDir)")
            logger.debug("tempDir: \(environment.tempDir)")
        }
        
        public func terminate() {
            messageReceiver.terminate()
        }
        
        public func start() throws {
            do {
                try messageReceiver.start { (endPoint, header, message, next) in
                    self.logger.debug("\(endPoint), \(header), \(message)")
                    next()
                }
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        private let queue: DispatchQueue
        private let environment: Environment
        private let logger: Logger
     
        private let messageReceiver: MessageReceiver
    }
    
    private init(impl: Impl) {
        self.impl = impl
    }
    
    private let impl: Impl
}
