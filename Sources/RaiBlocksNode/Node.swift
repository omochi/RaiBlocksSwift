import RaiBlocksSocket
import RaiBlocksBasic

import Foundation

public class Node {
    public struct Config {
        public var recoveryInterval: TimeInterval
        public var peerPort: Int
        public var refreshInterval: TimeInterval
        public var offlineInterval: TimeInterval
        public var initialPeerHostnames: [String]
        
        public init() {
            self.recoveryInterval = 10
            self.peerPort = 7075
            self.refreshInterval = 60
            self.offlineInterval = 60 * 5
            self.initialPeerHostnames = ["rai.raiblocks.net"]
        }
    }
    
    public convenience init(environment: Environment,
                            logger: Logger,
                            config: Node.Config,
                            queue: DispatchQueue) {
        self.init(impl: NodeImpl(environment: environment,
                                 logger: logger,
                                 config: config,
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
    
    private init(impl: NodeImpl) {
        self.impl = impl
    }
    
    private let impl: NodeImpl
}
