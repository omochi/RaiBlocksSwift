import RaiBlocksSocket
import RaiBlocksBasic

import Foundation

public class Node {
    public class Config {
        public let loggerConfig: Logger.Config
        public let fileSystem: FileSystem
        public let network: Network
        public let storage: Storage
        public let recoveryInterval: TimeInterval
        public let refreshInterval: TimeInterval
        public let offlineInterval: TimeInterval
        public let sendingBufferSize: Int
        
        public init(loggerConfig: Logger.Config,
                    fileSystem: FileSystem,
                    network: Network,
                    storage: Storage,
                    recoveryInterval: TimeInterval = 10,
                    refreshInterval: TimeInterval = 60,
                    offlineInterval: TimeInterval = 60 * 5,
                    sendingBufferSize: Int = 100 * 1000
                    )
        {
            self.loggerConfig = loggerConfig
            self.fileSystem = fileSystem
            self.network = network
            self.storage = storage
            self.recoveryInterval = recoveryInterval
            self.refreshInterval = refreshInterval
            self.offlineInterval = offlineInterval
            self.sendingBufferSize = sendingBufferSize
        }
    }
    
    public convenience init(queue: DispatchQueue,
                            config: Node.Config)
    {
        self.init(impl: NodeImpl(queue: queue,
                                 config: config))
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
