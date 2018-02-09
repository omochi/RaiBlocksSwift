import Foundation
import RaiBlocksBasic
import RaiBlocksNode

public class BootstrapDriver {
    public init(queue: DispatchQueue,
                network: Network,
                hostname: String,
                port: Int,
                errorHandler: @escaping (Error) -> Void)
    {
        self.queue = queue
        let writer = MessageWriter()
        self.client = BootstrapClient(queue: queue,
                                      network: network,
                                      messageWriter: writer)
        self.hostname = hostname
        self.port = port
        self.errorHandler = errorHandler
        self.terminated = false
        start()
    }
    
    public func terminate() {
        terminated = true
        client.terminate()
    }
    
    private func start() {
        func proc1() {
            if terminated { return }
            
            client.connect(protocolFamily: .ipv4,
                           hostname: hostname,
                           port: port,
                           successHandler: { proc1() },
                           errorHandler: { self.handleError($0) }
            )
        }
        
        func proc2() {
            if terminated { return }
            
            
            
        }
        
        proc1()
    }
    
    private func handleError(_ error: Error) {
        if terminated {
            return
        }
        errorHandler(error)
    }
    
    private let queue: DispatchQueue
    private let client: BootstrapClient
    private let hostname: String
    private let port: Int
    private let errorHandler: (Error) -> Void
    private var terminated: Bool
}
