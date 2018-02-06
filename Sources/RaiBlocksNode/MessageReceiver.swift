import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class MessageReceiver {
    public typealias Handler = (EndPoint, Message.Header, Message) -> Void
    
    public init(queue: DispatchQueue,
                loggerConfig: Logger.Config,
                network: Network,
                socket: UDPSocket,
                handler: @escaping Handler,
                errorHandler: @escaping (Error) -> Void)
    {
        self.queue = queue
        self.logger = Logger(config: loggerConfig, tag: "MessageReceiver")
        self.network = network
        self.messageReader = MessageReader()
        self.socket = socket
        self.handler = handler
        self.errorHandler = errorHandler
        self.terminated = false
        receive()
    }
    
    public func terminate() {
        terminated = true
    }
    
    private func receive() {
        logger.trace("receive")
        
        func next() {
            if self.terminated {
                self.logger.trace("receive.exit: terminated")
                return
            }
            
            self.receive()
        }
        
        socket.receive(size: 2048,
                       successHandler: { (data, endPoint) in
                        if self.terminated { return }
                        
                        do {
                            let (header, message) = try self.messageReader.read(data: data, network: self.network)
                            
//                            self.logger.debug("message: endPoint=\(endPoint), header=\(header), message=\(message)")
                            
                            self.handler(endPoint, header, message)
                            next()
                        } catch let error {
                            self.logger.debug("message read error: \(error), endPoint=\(endPoint)")
//                            self.logger.debug("data=\(data.toHex())")
                            next()
                        }
        },
                       errorHandler: { (error) in
                        if self.terminated { return }
                        
                        self.logger.error("socket.receive error: \(error)")
                        self.errorHandler(error)
        })
    }
    
    private let queue: DispatchQueue
    private let logger: Logger
    private let network: Network
    private let messageReader: MessageReader
    private let socket: UDPSocket
    private let handler: Handler
    private let errorHandler: ((Error) -> Void)
    private var terminated: Bool
}
