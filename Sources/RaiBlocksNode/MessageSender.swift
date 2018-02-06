import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class MessageSender {
    public struct Entry {
        public var endPoints: [EndPoint]
        public var message: Message
    }
    
    public init(queue: DispatchQueue,
                loggerConfig: Logger.Config,
                network: Network,
                socket: UDPSocket,
                bufferSize: Int,
                errorHandler: @escaping (Error) -> Void)
    {
        self.queue = queue
        self.logger = Logger(config: loggerConfig, tag: "MessageSender")
        self.network = network
        self.messageWriter = MessageWriter()
        self.socket = socket
        self.bufferSize = bufferSize
        self.errorHandler = errorHandler
        
        self.terminated = false
        self.buffer = []
        self.endPointIndex = 0
        self.sending = false
    }
    
    public func terminate() {
        self.terminated = true
        self.buffer.removeAll()
        self.endPointIndex = 0
        self.sending = false
    }
    
    public func send(endPoints: [EndPoint],
                     message: Message)
    {
        if buffer.count == bufferSize {
            logger.warn("buffer is full. discard message: \(message)")
            return
        }
                
        buffer.append(Entry(endPoints: endPoints, message: message))
        update()
    }
    
    private func update() {
        if sending {
            return
        }
        if buffer.count == 0 {
            return
        }
 
        let entry = self.buffer.first!
        let endPoint: EndPoint = entry.endPoints[endPointIndex]
        let message = entry.message
 
        logger.trace("socket.send: \(endPoint), \(message)")
        
        let data = messageWriter.write(message: message, network: network)
        
        sending = true
        socket.send(data: data,
                    endPoint: endPoint,
                    successHandler: { size in
                        if self.terminated { return }
                        
                        self.logger.trace("socket.send end: \(size)")
                        self.sending = false
                        
                        self.endPointIndex += 1
                        if self.endPointIndex == entry.endPoints.count {
                            self.buffer.removeFirst()
                            self.endPointIndex = 0
                        }
                        
                        self.update()
        },
                    errorHandler: { error in
                        if self.terminated { return }
                        
                        self.logger.error("socket.send error: \(error)")
                        self.sending = false
                        
                        self.errorHandler(error)                        
        })
        
    }
    
    private let queue: DispatchQueue
    private let logger: Logger
    private let network: Network
    private let messageWriter: MessageWriter
    private let socket: UDPSocket
    private let bufferSize: Int
    private let errorHandler: ((Error) -> Void)
    
    private var terminated: Bool
    private var buffer: [Entry]
    private var endPointIndex: Int
    
    private var sending: Bool 
}
