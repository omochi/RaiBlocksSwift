import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class InitialPeerResolver {
    public init(logger: Logger,
                queue: DispatchQueue,
                hostnames: [String],
                recoveryInterval: TimeInterval,
                endPointsHandler: @escaping ([EndPoint]) -> Void,
                completeHandler: @escaping () -> Void)
    {
        self.logger = Logger(config: logger.config, tag: "InitialPeerResolver")
        self.queue = queue
        self.hostnames = hostnames
        self.recoveryInterval = recoveryInterval
        self.endPointsHandler = endPointsHandler
        self.completeHandler = completeHandler
        
        self.terminated = false
        self.hostnameIndex = 0
        
        update()
    }
    
    public func terminate() {
        recoveryTimer?.cancel()
        recoveryTimer = nil
        
        task?.terminate()
        task = nil
        
        terminated = true
    }
    
    private func update() {
        if hostnameIndex == hostnames.count {
            logger.trace("complete")
            terminate()
            completeHandler()
            return
        }
        
        if self.task != nil {
            return
        }
        
        let hostname = hostnames[hostnameIndex]
        logger.trace("nameResolve(\(hostname))")
        task = nameResolve(protocolFamily: .ipv4,
                           hostname: hostname,
                           callbackQueue: queue,
                           successHandler: { (endPoints) in
                            var endPoints = endPoints
                            
                            self.logger.trace("nameResolve.success: \(endPoints)")
                            self.task?.terminate()
                            self.task = nil
                            
                            endPoints = endPoints.map { endPoint in
                                EndPoint.ipv6(endPoint.toV6())
                            }
                            endPoints = Set(endPoints).map { $0 }
                            
                            self.endPointsHandler(endPoints)
                            self.hostnameIndex += 1
                            self.update()
        },
                           errorHandler: { error in
                            self.logger.debug("nameResolve error: \(error), recoveryInterval=\(self.recoveryInterval)")
                            self.task?.terminate()
                            self.task = nil
                            self.recoveryTimer = makeTimer(delay: self.recoveryInterval, queue: self.queue) {
                                if self.terminated { return }
                                self.update()
                            }
        })
    }
    
    private let logger: Logger
    private let queue: DispatchQueue
    private let hostnames: [String]
    private let recoveryInterval: TimeInterval
    private let endPointsHandler: ([EndPoint]) -> Void
    private let completeHandler: () -> Void
    
    private var terminated: Bool
    private var hostnameIndex: Int
    private var task: NameResolveTask?
    private var recoveryTimer: DispatchSourceTimer?
    
}
