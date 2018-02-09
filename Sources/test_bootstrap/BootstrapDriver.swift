import Foundation
import RaiBlocksBasic
import RaiBlocksNode

public class BootstrapDriver {
    public init(queue: DispatchQueue,
                network: Network,
                hostname: String,
                errorHandler: @escaping (Error) -> Void)
    {
        self.queue = queue
        let writer = MessageWriter()
        self.client = BootstrapClient(queue: queue,
                                      network: network,
                                      messageWriter: writer)
        self.hostname = hostname
        self.errorHandler = errorHandler
        self.terminated = false
        start()
    }
    
    deinit {
        print("deinit")
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
                           port: network.peerPort,
                           successHandler: { proc2() },
                           errorHandler: { self.doError($0) }
            )
        }
        
        func proc2() {
            if terminated { return }
            
            print("proc2")
            
            client.requestAccount(entryHandler: { (entry, next) in
                print(entry)
                proc3()
            },
                                  errorHandler: { self.doError($0) })
        }
        
        func proc3() {
            terminate()
        }
        
        proc1()
    }
    
    private func doError(_ error: Error) {
        if terminated { return }
        errorHandler(error)
    }
    
    private let queue: DispatchQueue
    private let client: BootstrapClient
    private let hostname: String
    private let errorHandler: (Error) -> Void
    private var terminated: Bool
}
