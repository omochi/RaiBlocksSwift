import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class InitialPeerResolver {
    public init(queue: DispatchQueue,
                loggerConfig: Logger.Config,
                hostnames: [String],
                peerPort: Int,
                recoveryInterval: TimeInterval,
                endPointsHandler: @escaping ([IPv6.EndPoint]) -> Void,
                completeHandler: @escaping () -> Void)
    {
        self.queue = queue
        self.logger = Logger(config: loggerConfig, tag: "InitialPeerResolver")
        self.hostnames = hostnames
        self.peerPort = peerPort
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
        task = nameResolve(queue: queue,
                           protocolFamily: .ipv4,
                           hostname: hostname,
                           successHandler: { (endPoints) in
                            self.logger.trace("nameResolve.success: \(endPoints)")
                            self.task?.terminate()
                            self.task = nil
                            
                            var endPoints: [IPv6.EndPoint] = endPoints.map { $0.toV6() }
                            endPoints = Set(endPoints).map { $0 }
                            endPoints = endPoints.map {
                                var endPoint = $0
                                endPoint.port = self.peerPort
                                return endPoint
                            }

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
    
    private let queue: DispatchQueue
    private let logger: Logger
    private let hostnames: [String]
    private let peerPort: Int
    private let recoveryInterval: TimeInterval
    private let endPointsHandler: ([IPv6.EndPoint]) -> Void
    private let completeHandler: () -> Void
    
    private var terminated: Bool
    private var hostnameIndex: Int
    private var task: NameResolveTask?
    private var recoveryTimer: DispatchSourceTimer?
    
}
