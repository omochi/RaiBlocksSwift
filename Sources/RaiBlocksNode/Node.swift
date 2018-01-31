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
            self.environment = environment
            self.queue = queue
            self.logger = Logger(config: Logger.Config(level: .trace), tag: "Node")
            self.messageReceiver = MessageReceiver(queue: queue,
                                                   logger: logger)
            
            try messageReceiver.start { (endPoint, header, message, next) in
                self.logger.debug("\(endPoint), \(header), \(message)")
                next()
            }
        }
        
        public func terminate() {
            messageReceiver.terminate()
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
