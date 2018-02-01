import RaiBlocksSocket
import RaiBlocksBasic

import Foundation

public class Node {
    public convenience init(environment: Environment,
                            logger: Logger,
                            queue: DispatchQueue) {
        self.init(impl: NodeImpl(environment: environment,
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
    
    
    private init(impl: NodeImpl) {
        self.impl = impl
    }
    
    private let impl: NodeImpl
}
