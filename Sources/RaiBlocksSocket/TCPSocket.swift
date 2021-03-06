import Foundation
import RaiBlocksPosix
import RaiBlocksRandom

public class TCPSocket {
    public enum State {
        case inited
        case connecting
        case connected
        case listening
        case closed
    }
    
    public convenience init(queue: DispatchQueue) throws {
        let impl = try Impl.init(queue: queue)
        self.init(impl: impl)
    }
    
    deinit {
        close()
    }
    
    public var state: State {
        return impl.state
    }
    
    public var protocolFamily: ProtocolFamily? {
        return impl.protocolFamily
    }
    
    public func close() {
        impl.close()
    }
    
    public func connect(protocolFamily: ProtocolFamily,
                        hostname: String,
                        port: Int,
                        successHandler: @escaping () -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        impl.connect(protocolFamily: protocolFamily,
                     hostname: hostname,
                     port: port,
                     successHandler: successHandler,
                     errorHandler: errorHandler)
    }
    
    public func connect(endPoint: EndPoint,
                        successHandler: @escaping () -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        impl.connect(endPoint: endPoint,
                     successHandler: successHandler,
                     errorHandler: errorHandler)
    }
    
    public func send(data: Data,
                     successHandler: @escaping () -> Void,
                     errorHandler: @escaping (Error) -> Void)
    {
        impl.send(data: data,
                  successHandler: successHandler,
                  errorHandler: errorHandler)
    }
    
    public func receive(size: Int?,
                        successHandler: @escaping (Data) -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        impl.receive(size: size,
                     successHandler: successHandler,
                     errorHandler: errorHandler)
    }
    public func listen(protocolFamily: ProtocolFamily, port: Int, backlog: Int = 8) throws {
        try impl.listen(protocolFamily: protocolFamily,
                        port: port, backlog: backlog)
    }
    
    public func accept(successHandler: @escaping (TCPSocket) -> Void,
                       errorHandler: @escaping (Error) -> Void)
    {
        impl.accept(successHandler: successHandler,
                    errorHandler: errorHandler)
    }
    
    private class Impl {
        public init(queue: DispatchQueue) throws {
            self.queue = queue
            socket = nil
            _endPoint = nil
            _state = .inited
        }
        
        public var state: State {
            return _state
        }
        
        public var protocolFamily: ProtocolFamily? {
            return socket?.protocolFamily
        }
        
        public var endPoint: EndPoint? {
            return _endPoint
        }
        
        public func close() {
            if _state == .closed { return }
            
            _close()
            _state = .closed
        }
        
        public func connect(protocolFamily: ProtocolFamily,
                            hostname: String,
                            port: Int,
                            successHandler: @escaping () -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            precondition(_state == .inited)
            precondition(connectTask == nil)
            
            var task: ConnectTask?
            
            let nameTask = nameResolve(queue: queue,
                                       protocolFamily: protocolFamily,
                                       hostname: hostname,
                                       successHandler: {
                                        resolveHandler(endPoints: $0) },
                                       errorHandler: { error in
                                        self.doError(error: error,
                                                     callbackHandler: errorHandler) }
            )
            task = ConnectTask.init(nameResolveTask: nameTask,
                                    successHandler: successHandler,
                                    errorHandler: errorHandler)
            self.connectTask = task
            _state = .connecting
            
            func resolveHandler(endPoints: [EndPoint]) {
                let task = task!
                
                do {
                    guard var endPoint = endPoints.getRandomElement() else {
                        throw SocketError.init(message: "name resolve failed, no entry: hostname=\(hostname)")
                    }
                    endPoint.port = port
                                            print("connect: \(endPoint)")
                    try self._connect(endPoint: endPoint,
                                      successHandler: task.successHandler,
                                      errorHandler: task.errorHandler)
                } catch let error {
                    self.doError(error: error, callbackHandler: task.errorHandler)
                }
            }
        }
        
        public func connect(endPoint: EndPoint,
                            successHandler: @escaping () -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            do {
                precondition(_state == .inited)
                precondition(connectTask == nil)
                try _connect(endPoint: endPoint,
                             successHandler: successHandler,
                             errorHandler: errorHandler)
            } catch let error {
                self.doError(error: error, callbackHandler: errorHandler)
            }
        }
        
        public func send(data: Data,
                         successHandler: @escaping () -> Void,
                         errorHandler: @escaping (Error) -> Void)
        {
            precondition(_state == .connected)
            precondition(sendTask == nil)
            
            let socket = self.socket!
            precondition(socket.writeSuspended)
            
            let task = SendTask.init(data: data,
                                     successHandler: successHandler,
                                     errorHandler: errorHandler)
            sendTask = task
            socket.awaitWriteEvent {
                self.doSend()
            }
        }
        
        public func receive(size: Int?,
                            successHandler: @escaping (Data) -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            precondition(_state == .connected)
            precondition(receiveTask == nil)
            
            let socket = self.socket!
            precondition(socket.readSuspended)
            
            let task = ReceiveTask.init(size: size,
                                        successHandler: successHandler,
                                        errorHandler: errorHandler)
            receiveTask = task
            socket.awaitReadEvent {
                self.doReceive()
            }
        }
        
        public func listen(protocolFamily: ProtocolFamily, port: Int, backlog: Int) throws {
            func body() throws {
                precondition(_state == .inited)
                precondition(self.socket == nil)
                
                let socket = try DispatchSocket(queue: queue,
                                                protocolFamily: protocolFamily,
                                                type: SOCK_STREAM)
                self.initSocket(socket)
                try socket.setSockOpt(level: SOL_SOCKET, name: SO_REUSEADDR, value: 1)
                let endPoint: EndPoint = .listening(protocolFamily: protocolFamily, port: port)
                try socket.bind(endPoint: endPoint)
                try socket.listen(backlog: backlog)
                _state = .listening
            }
            
            do {
                try body()
            } catch let error {
                _close()
                _state = .closed
                throw error
            }
        }

        public func accept(successHandler: @escaping (TCPSocket) -> Void,
                           errorHandler: @escaping (Error) -> Void)
        {
            precondition(_state == .listening)
            precondition(acceptTask == nil)
            
            let socket = self.socket!
            precondition(socket.readSuspended)
            
            let task = AcceptTask.init(successHandler: successHandler,
                                       errorHandler: errorHandler)
            acceptTask = task
            socket.awaitReadEvent {
                self.doAccept()
            }
        }
        
        private func initSocket(_ socket: DispatchSocket) {
            precondition(_state == .inited || _state == .connecting)
            precondition(self.socket == nil)
            self.socket = socket
        }

        private func _connect(endPoint: EndPoint,
                              successHandler: @escaping () -> Void,
                              errorHandler: @escaping (Error) -> Void) throws {
            let socket = try DispatchSocket(queue: queue,
                                            protocolFamily: endPoint.protocolFamily,
                                            type: SOCK_STREAM)
            self.initSocket(socket)
            assert(socket.writeSuspended)
            
            
            do {
                try socket.connect(endPoint: endPoint)
            } catch let e as PosixError {
                if e.errno != EINPROGRESS {
                    throw e
                }
            }

            let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timer.schedule(deadline: .now() + connectTimeoutInterval)
            timer.setEventHandler {
                self.doError(error: SocketError.init(message: "connect(\(endPoint)) timeout"),
                             callbackHandler: errorHandler)
            }
            timer.resume()
            let task = ConnectTask.init(endPoint: endPoint,
                                        timer: timer,
                                        successHandler: successHandler,
                                        errorHandler: errorHandler)
            connectTask = task
            _state = .connecting
            socket.awaitWriteEvent {
                self.doConnectSuccess()
            }
        }
        
        private func doConnectSuccess() {
            assert(_state == .connecting)
            
            let task = connectTask!
            task.close()
            connectTask = nil
            
            _state = .connected
            _endPoint = task.endPoint
            
            postCallback {
                task.successHandler()
            }
        }
        
        private func _close() {
            _endPoint = nil
            
            connectTask?.close()
            connectTask = nil
            
            receiveTask = nil
            sendTask = nil
            acceptTask = nil
            
            socket?.close()
            socket = nil
        }
        
        private func doSend() {
            let task = sendTask!
            
            func body() throws {
                let socket = self.socket!
                
                let sentSize: Int
                do {
                    let offset = task.sentSize
                    let chunk = task.data.subdata(in: offset..<task.data.count - offset)
                    sentSize = try socket.send(data: chunk)
                } catch let e as PosixError {
                    if e.errno == EAGAIN {
                        socket.awaitWriteEvent {
                            self.doSend()
                        }
                        return
                    }
                    throw e
                }
                
                task.sentSize += sentSize
                if task.sentSize < task.data.count {
                    return
                }
                
                sendTask = nil
                postCallback {
                    task.successHandler()
                }
            }
            
            do {
                try body()
            } catch let error {
                sendTask = nil
                doError(error: error, callbackHandler: task.errorHandler)
            }
        }
        
        private func doReceive() {
            let task = receiveTask!
            
            func body() throws {
                let socket = self.socket!
                
                while true {
                    let chunkSize: Int
                    
                    if let size = task.size {
                        let rem = size - task.data.count
                        if rem == 0 {
                            break
                        }
                        chunkSize = rem
                    } else {
                        chunkSize = 1024
                    }
                    
                    let chunk: Data
                    do {
                        chunk = try socket.recv(size: chunkSize)
                    } catch let e as PosixError {
                        if e.errno == EAGAIN {
                            if let _ = task.size {
                                socket.awaitReadEvent {
                                    self.doReceive()
                                }
                                return
                            } else {
                                break
                            }
                        }
                        throw e
                    }
                    
                    if chunk.count == 0 {
                        if let size = task.size {
                            throw SocketError.init(message: "receive(\(task.data.count)/\(size)) failed: connection closed")
                        } else {
                            break
                        }
                    }
                    task.data.append(chunk)
                }
                
                receiveTask = nil
                postCallback {
                    task.successHandler(task.data)
                }
            }
            
            do {
                try body()
            } catch let error {
                receiveTask = nil
                doError(error: error, callbackHandler: task.errorHandler)
            }
        }
        
        private func doAccept() {
            let task = acceptTask!
            
            func body() throws {
                let socket = self.socket!
                
                let newSocketImpl = try Impl.init(queue: queue)
                
                let (rawSocket, endPoint): (DispatchSocket, EndPoint)
                do {
                    (rawSocket, endPoint) = try socket.accept(queue: newSocketImpl.queue)
                } catch let e as PosixError {
                    if e.errno == EWOULDBLOCK {
                        socket.awaitReadEvent {
                            self.doAccept()
                        }
                        return
                    }
                    throw e
                }

                newSocketImpl.initSocket(rawSocket)
                newSocketImpl._endPoint = endPoint
                newSocketImpl._state = .connected
                let newSocket = TCPSocket.init(impl: newSocketImpl)
                
                acceptTask = nil
                
                postCallback {
                    task.successHandler(newSocket)
                }
            }
            
            do {
                try body()
            } catch let error {
                acceptTask = nil
                doError(error: error, callbackHandler: task.errorHandler)
            }
        }
        
        private func doError(error: Error,
                             callbackHandler: @escaping (Error) -> Void)
        {
            _close()
            postCallback {
                self._state = .closed
                callbackHandler(error)
            }
        }
        
        private func postCallback(_ f: @escaping () -> Void) {
            if _state == .closed { return }
            f()
        }
        
        private let queue: DispatchQueue
        private let connectTimeoutInterval: Double = 10.0
        
        private var _state: State
        private var socket: DispatchSocket?
        private var _endPoint: EndPoint?
        private var connectTask: ConnectTask?
        private var sendTask: SendTask?
        private var receiveTask: ReceiveTask?
        private var acceptTask: AcceptTask?
    }

    private class ConnectTask {
        public let nameResolveTask: NameResolveTask?
        public let endPoint: EndPoint?
        public let timer: DispatchSourceTimer?
        public let successHandler: () -> Void
        public let errorHandler: (Error) -> Void
        
        public init(nameResolveTask: NameResolveTask,
                    successHandler: @escaping () -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.nameResolveTask = nameResolveTask
            self.endPoint = nil
            self.timer = nil
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
        
        public init(endPoint: EndPoint,
                    timer: DispatchSourceTimer,
                    successHandler: @escaping () -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.nameResolveTask = nil
            self.endPoint = endPoint
            self.timer = timer
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
        
        public func close() {
            nameResolveTask?.terminate()
            timer?.cancel()
        }
    }
    
    private class SendTask {
        public let data: Data
        public var sentSize: Int
        public let successHandler: () -> Void
        public let errorHandler: (Error) -> Void
        
        public init(data: Data,
                    successHandler: @escaping () -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.data = data
            sentSize = 0
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
    }
    
    private class ReceiveTask {
        public var data: Data
        public var size: Int?
        public let successHandler: (Data) -> Void
        public let errorHandler: (Error) -> Void
        
        public init(size: Int?,
                    successHandler: @escaping (Data) -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.data = Data.init()
            self.size = size
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
    }
    
    private class AcceptTask {
        public let successHandler: (TCPSocket) -> Void
        public let errorHandler: (Error) -> Void
        
        public init(successHandler: @escaping (TCPSocket) -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
    }
    
    private init(impl: Impl) {
        self.impl = impl
    }
    
    private let impl: Impl
}
