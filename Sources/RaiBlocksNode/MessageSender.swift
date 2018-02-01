import Foundation
import RaiBlocksSocket
import RaiBlocksBasic

public class MessageSender {
    public struct Entry {
        public var endPoints: [EndPoint]
        public var message: Message
    }
    
    public init(queue: DispatchQueue,
                logger: Logger,
                socket: UDPSocket,
                errorHandler: @escaping (Error) -> Void)
    {
        self.queue = queue
        self.logger = logger
        self.messageWriter = MessageWriter()
        self.socket = socket
        self.errorHandler = errorHandler
        
        self.terminated = false
        self.entries = []
        self.endPointIndex = 0
        self.sending = false
    }
    
    public func terminate() {
        self.terminated = true
        self.entries.removeAll()
        self.endPointIndex = 0
        self.sending = false
    }
    
    public func send(endPoints: [EndPoint],
                     message: Message)
    {
        self.entries.append(Entry(endPoints: endPoints, message: message))
        update()
    }
    
    private func update() {
        if sending {
            return
        }
        if entries.count == 0 {
            return
        }
 
        let entry = self.entries.first!
        let endPoint = entry.endPoints[endPointIndex]
        let message = entry.message
 
        logger.trace("socket.send: \(endPoint), \(message)")
        
        let data = messageWriter.write(message: message)
        
        sending = true
        socket.send(data: data, endPoint: endPoint,
                    successHandler: { size in
                        if self.terminated { return }
                        
                        self.logger.trace("socket.send end: \(size)")
                        self.sending = false
                        
                        self.endPointIndex += 1
                        if self.endPointIndex == entry.endPoints.count {
                            self.entries.removeFirst()
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
    private let messageWriter: MessageWriter
    private let socket: UDPSocket
    private let errorHandler: ((Error) -> Void)
    
    private var terminated: Bool
    private var entries: [Entry]
    private var endPointIndex: Int
    
    private var sending: Bool 
}
