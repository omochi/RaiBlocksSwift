import Foundation
import RaiBlocksPosix

public class UDPSocket {
    public enum State {
        case inited
        case opened
        case closed
    }
    
    public convenience init(callbackQueue: DispatchQueue) {
        let impl = Impl.init(callbackQueue: callbackQueue)
        self.init(impl: impl)
    }
    
    deinit {
        close()
    }
    
    public var state: State {
        return impl.state
    }
    
    public func getLocalEndPoint() throws -> EndPoint {
        return try impl.getLocalEndPoint()
    }
    
    public func open(protocolFamily: ProtocolFamily) throws {
        try impl.open(protocolFamily: protocolFamily)
    }
    
    public func close() {
        impl.close()
    }
    
    public func send(data: Data,
                     endPoint: EndPoint,
                     successHandler: @escaping (Int) -> Void,
                     errorHandler: @escaping (Error) -> Void)
    {
        impl.send(data: data, endPoint: endPoint,
                  successHandler: successHandler, errorHandler: errorHandler)
    }
    
    public func receive(size: Int,
                        successHandler: @escaping (Data, EndPoint) -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        impl.receive(size: size,
                     successHandler: successHandler,
                     errorHandler: errorHandler)
    }
    
    private class Impl {
        public init(callbackQueue: DispatchQueue) {
            self.queue = DispatchQueue.init(label: "UDPSocket.Impl.queue")
            self.callbackQueue = callbackQueue
            
            self._state = .inited
        }
        
        public var state: State {
            return queue.sync { _state }
        }
        
        public func close() {
            queue.sync {
                if _state == .closed {
                    return
                }
                
                _close()
                _state = .closed
            }
        }
        
        public func open(protocolFamily: ProtocolFamily) throws {
            try queue.sync {
                precondition(_state == .inited)
                
                let _ = try initSocket {
                    try RawDispatchSocket(protocolFamily: protocolFamily, type: SOCK_DGRAM, queue: queue)
                }
                
                _state = .opened
            }
        }
        
        public func send(data: Data,
                         endPoint: EndPoint,
                         successHandler: @escaping (Int) -> Void,
                         errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                precondition(_state == .opened)
                precondition(sendTask == nil)
                
                let socket = self.socket!
                precondition(socket.writeSuspended)
                
                socket.resumeWrite()
                
                let task = SendTask.init(data: data,
                                         endPoint: endPoint,
                                         successHandler: successHandler,
                                         errorHandler: errorHandler)
                sendTask = task
            }
        }
        
        public func receive(size: Int,
                            successHandler: @escaping (Data, EndPoint) -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                precondition(_state == .opened)
                precondition(receiveTask == nil)
                
                let socket = self.socket!
                precondition(socket.readSuspended)
                
                socket.resumeRead()
                
                let task = ReceiveTask.init(size: size,
                                            successHandler: successHandler,
                                            errorHandler: errorHandler)
                receiveTask = task
            }
        }
        
        public func getLocalEndPoint() throws -> EndPoint {
            return try queue.sync {
                try socket!.getSockName()
            }
        }
        
        private func initSocket(_ socketFactory: () throws -> RawDispatchSocket) rethrows -> RawDispatchSocket {
            precondition(_state == .inited)
            precondition(self.socket == nil)
            
            let socket = try socketFactory()
            self.socket = socket
            
            socket.setReadHandler {
                switch self._state {
                case .opened:
                    self.doReceive()
                default:
                    return
                }
            }
            
            socket.setWriteHandler {
                switch self._state {
                case .opened:
                    self.doSend()
                default:
                    return
                }
            }
            
            return socket
        }
        
        private func _close() {
            sendTask = nil
            receiveTask = nil
            
            socket?.close()
            socket = nil
        }
        
        private func doSend() {
            let task = sendTask!
            
            func body() throws {
                let socket = self.socket!
                
                let sentSize: Int
                do {
                    sentSize = try socket.sendTo(data: task.data, endPoint: task.endPoint)
                } catch let e as PosixError {
                    if e.errno == EAGAIN {
                        return
                    }
                    throw e
                }
                
                sendTask = nil
                socket.suspendWrite()
                postCallback {
                    return { task.successHandler(sentSize) }
                }
            }
            
            do {
                try body()
            } catch let error {
                postError(error, handler: task.errorHandler)
            }
        }
        
        private func doReceive() {
            let task = receiveTask!
            
            func body() throws {
                let socket = self.socket!
                
                let (chunk, endPoint): (Data, EndPoint)
                do {
                    (chunk, endPoint) = try socket.recvFrom(size: task.size)
                } catch let e as PosixError {
                    if e.errno == EAGAIN {
                        return
                    }
                    throw e
                }
                
                receiveTask = nil
                socket.suspendRead()
                postCallback {
                    return { task.successHandler(chunk, endPoint) }
                }
            }
            
            do {
                try body()
            } catch let error {
                postError(error, handler: task.errorHandler)
            }
        }
        
        private func postError(_ error: Error,
                               handler: @escaping (Error) -> Void)
        {
            _close()
            postCallback {
                self._state = .closed
                return { handler(error) }
            }
        }
        
        private func postCallback(_ f: @escaping () -> () -> Void) {
            callbackQueue.async {
                let next: () -> Void = self.queue.sync {
                    if self._state == .closed {
                        return {}
                    }
                    return f()
                }
                next()
            }
        }
        
        private let queue: DispatchQueue
        private let callbackQueue: DispatchQueue
        
        private var _state: State
        private var socket: RawDispatchSocket?
        
        private var sendTask: SendTask?
        private var receiveTask: ReceiveTask?
    }

    private class SendTask {
        public var data: Data
        public let endPoint: EndPoint
        public var successHandler: (Int) -> Void
        public var errorHandler: (Error) -> Void
        
        public init(data: Data,
                    endPoint: EndPoint,
                    successHandler: @escaping (Int) -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.data = data
            self.endPoint = endPoint
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
    }
    
    private class ReceiveTask {
        public let size: Int
        public let successHandler: (Data, EndPoint) -> Void
        public let errorHandler: (Error) -> Void
        
        public init(size: Int,
                    successHandler: @escaping (Data, EndPoint) -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.size = size
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
    }
    
    private init(impl: Impl) {
        self.impl = impl
    }
    
    private let impl: Impl
}
