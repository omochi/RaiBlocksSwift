import Foundation

public class TCPSocket {
    public convenience init(callbackQueue: DispatchQueue) throws {
        let impl = try Impl.init(callbackQueue: callbackQueue)
        self.init(impl: impl)
    }
    
    deinit {
        close()
    }
    
    public func close() {
        impl.close()
    }
    
    public func connect(protocolFamily: SocketProtocolFamily,
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
    
    public func connect(endPoint: SocketEndPoint,
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
    
    public func receive(maxSize: Int,
                        successHandler: @escaping (Data) -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        impl.receive(maxSize: maxSize,
                     successHandler: successHandler,
                     errorHandler: errorHandler)
    }
    public func listen(protocolFamily: SocketProtocolFamily, port: Int, backlog: Int = 8) throws {
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
        public init(callbackQueue: DispatchQueue) throws {
            queue = DispatchQueue.init(label: "TCPSocket.Impl.queue")
            socket = nil
            _endPoint = nil
            self.callbackQueue = callbackQueue
            state = .inited
        }
        
        public var endPoint: SocketEndPoint? {
            return queue.sync { _endPoint }
        }
        
        public func close() {
            queue.sync {
                if state == .closed {
                    return
                }
                
                _close()
                state = .closed
            }
        }
        
        public func connect(protocolFamily: SocketProtocolFamily,
                            hostname: String,
                            port: Int,
                            successHandler: @escaping () -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                precondition(state == .inited)
                precondition(connectTask == nil)
                
                var task: ConnectTask?
                
                let nameTask = nameResolve(protocolFamily: protocolFamily,
                                           hostname: hostname,
                                           callbackQueue: queue,
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
                state = .connecting
                
                func resolveHandler(endPoints: [SocketEndPoint]) {
                    let task = task!
                    guard self.connectTask === task else { return }
                    
                    do {
                        guard var endPoint = endPoints.getRandom() else {
                            throw GenericError.init(message: "name resolve failed, no entry: hostname=\(hostname)")
                        }
                        endPoint.port = port
                        try self._connect(endPoint: endPoint,
                                          successHandler: task.successHandler,
                                          errorHandler: task.errorHandler)
                    } catch let error {
                        self.doError(error: error, callbackHandler: task.errorHandler)
                    }
                }
            }
        }
        
        public func connect(endPoint: SocketEndPoint,
                            successHandler: @escaping () -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                do {
                    precondition(state == .inited)
                    precondition(connectTask == nil)
                    try _connect(endPoint: endPoint,
                                 successHandler: successHandler,
                                 errorHandler: errorHandler)
                } catch let error {
                    self.doError(error: error, callbackHandler: errorHandler)
                }
            }
        }
        
        public func send(data: Data,
                         successHandler: @escaping () -> Void,
                         errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                precondition(state == .connected)
                precondition(sendTask == nil)
                
                let socket = self.socket!
                precondition(socket.writeSuspended)

                socket.resumeWrite()
                
                let task = SendTask.init(data: data,
                                         successHandler: successHandler,
                                         errorHandler: errorHandler)
                sendTask = task
            }
        }
        
        public func receive(maxSize: Int,
                            successHandler: @escaping (Data) -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                precondition(state == .connected)
                precondition(receiveTask == nil)
                
                let socket = self.socket!
                precondition(socket.readSuspended)
                
                socket.resumeRead()
                
                let task = ReceiveTask.init(maxSize: maxSize,
                                            successHandler: successHandler,
                                            errorHandler: errorHandler)
                receiveTask = task
            }
        }
        
        public func listen(protocolFamily: SocketProtocolFamily, port: Int, backlog: Int) throws {
            func body() throws {
                precondition(state == .inited)
                precondition(self.socket == nil)
                
                let socket = try initSocket(protocolFamily: protocolFamily, type: SOCK_STREAM)
                
                var st = socket.setSockOpt(level: SOL_SOCKET, name: SO_REUSEADDR, value: 1)
                if st != 0 {
                    throw PosixError.init(errno: errno, message: "setSockOpt(SO_REUSEADDR)")
                }
                
                let endPoint: SocketEndPoint
                switch protocolFamily {
                case .ipv6:
                    let sockAddr = sockaddr_in6.init(sin6_len: UInt8(MemoryLayout<sockaddr_in6>.size),
                                                     sin6_family: UInt8(AF_INET6),
                                                     sin6_port: NSSwapHostShortToBig(UInt16(port)),
                                                     sin6_flowinfo: 0,
                                                     sin6_addr: in6addr_any,
                                                     sin6_scope_id: 0)
                    endPoint = .ipv6(IPv6.EndPoint(sockAddr: sockAddr))
                case .ipv4:
                    let sockAddr = sockaddr_in.init(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                                    sin_family: UInt8(AF_INET),
                                                    sin_port: NSSwapHostShortToBig(UInt16(port)),
                                                    sin_addr: in_addr(s_addr: INADDR_ANY),
                                                    sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
                    endPoint = .ipv4(IPv4.EndPoint(sockAddr: sockAddr))
                }
                
                st = socket.bind(endPoint: endPoint)
                if st != 0 {
                    throw PosixError.init(errno: errno, message: "bind(\(port))")
                }
                
                st = socket.listen(backlog: backlog)
                if st != 0 {
                    throw PosixError.init(errno: errno, message: "listen(\(port))")
                }
                
                state = .listening
            }
            
            try queue.sync {
                do {
                    try body()
                } catch let error {
                    _close()
                    state = .closed
                    throw error
                }
            }
        }

        public func accept(successHandler: @escaping (TCPSocket) -> Void,
                           errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                precondition(state == .listening)
                precondition(acceptTask == nil)
                
                let socket = self.socket!
                precondition(socket.readSuspended)
                
                let task = AcceptTask.init(successHandler: successHandler,
                                           errorHandler: errorHandler)
                acceptTask = task
                socket.resumeRead()
            }
        }
        
        private func initSocket(protocolFamily: SocketProtocolFamily, type: Int32)
            throws -> RawDispatchSocket
        {
            let socket = try RawDispatchSocket.init(protocolFamily: protocolFamily,
                                                    type: type,
                                                    queue: queue)
            self.initSocket(socket)
            return socket
        }
        
        private func initSocket(fd: Int32,
                                protocolFamily: SocketProtocolFamily)
            throws -> RawDispatchSocket
        {
            let socket = try RawDispatchSocket.init(fd: fd,
                                                    protocolFamily: protocolFamily,
                                                    queue: queue)
            self.initSocket(socket)
            return socket
        }
        
        private func initSocket(_ socket: RawDispatchSocket) {
            assert(state == .inited || state == .connecting)
            assert(self.socket == nil)
            
            self.socket = socket

            socket.setReadHandler {
                switch self.state {
                case .connected:
                    self.doReceive()
                case .listening:
                    self.doAccept()
                default:
                    return
                }
            }
            
            socket.setWriteHandler {
                switch self.state {
                case .connecting:
                    self.doConnectSuccess()
                case .connected:
                    self.doSend()
                default:
                    return
                }
            }
        }

        private func _connect(endPoint: SocketEndPoint,
                              successHandler: @escaping () -> Void,
                              errorHandler: @escaping (Error) -> Void) throws {
            let socket = try initSocket(protocolFamily: endPoint.protocolFamily, type: SOCK_STREAM)
            assert(socket.writeSuspended)
            
            let st = socket.connect(endPoint: endPoint)
            if st != 0 {
                if errno != EINPROGRESS {
                    throw PosixError.init(errno: errno, message: "connect(\(endPoint))")
                }
            }
            
            socket.resumeWrite()
            
            let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timer.schedule(deadline: .now() + connectTimeoutInterval)
            timer.setEventHandler {
                self.doError(error: GenericError.init(message: "connect(\(endPoint)) timeout"),
                             callbackHandler: errorHandler)
            }
            timer.resume()
            let task = ConnectTask.init(endPoint: endPoint,
                                        timer: timer,
                                        successHandler: successHandler,
                                        errorHandler: errorHandler)
            connectTask = task
            state = .connecting
        }
        
        private func doConnectSuccess() {
            assert(state == .connecting)
            
            socket!.suspendWrite()
            
            let task = connectTask!
            task.close()
            connectTask = nil
            
            state = .connected
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
                
                let st = task.data.withUnsafeBytes { p in
                    socket.send(data: p + task.sentSize, size: task.data.count - task.sentSize)
                }
                if st == -1 {
                    if errno == EAGAIN {
                        return
                    }
                    
                    throw PosixError.init(errno: errno, message: "send()")
                }
                
                task.sentSize += st
                if task.sentSize < task.data.count {
                    return
                }
                
                sendTask = nil
                socket.suspendWrite()
                postCallback {
                    task.successHandler()
                }
            }
            
            do {
                try body()
            } catch let error {
                doError(error: error, callbackHandler: task.errorHandler)
            }
            
        }
        
        private func doReceive() {
            let task = receiveTask!
            
            func body() throws {
                let socket = self.socket!
                
                var data = Data.init()
                
                while true {
                    assert(data.count <= task.maxSize)
                    if data.count == task.maxSize {
                        break
                    }
                    
                    var chunk = Data.init(count: task.maxSize - data.count)
                    let st = chunk.withUnsafeMutableBytes { p in
                        socket.recv(data: p, size: chunk.count)
                    }
                    if st == -1 {
                        if errno == EAGAIN {
                            break
                        }
                        
                        throw PosixError.init(errno: errno, message: "read()")
                    } else if st == 0 {
                        break
                    }
                    chunk.count = st
                    data.append(chunk)
                }
                
                receiveTask = nil
                socket.suspendRead()
                postCallback {
                    task.successHandler(data)
                }
            }
            
            do {
                try body()
            } catch let error {
                doError(error: error, callbackHandler: task.errorHandler)
            }
        }
        
        private func doAccept() {
            let task = acceptTask!
            
            func body() throws {
                let socket = self.socket!
              
                let (st, endPoint) = socket.accept()
                if st == -1 {
                    if errno == EWOULDBLOCK {
                        return
                    }
                    
                    throw PosixError.init(errno: errno, message: "accept()")
                }
                
                let newSocket = try Impl.init(callbackQueue: callbackQueue)
                let _ = try newSocket.initSocket(fd: st, protocolFamily: socket.protocolFamily)
                newSocket._endPoint = endPoint
                newSocket.state = .connected
                
                acceptTask = nil
                socket.suspendRead()
                
                postCallback {
                    task.successHandler(TCPSocket.init(impl: newSocket))
                }
            }
            
            do {
                try body()
            } catch let error {
                doError(error: error, callbackHandler: task.errorHandler)
            }
        }
        
        private func doError(error: Error,
                             callbackHandler: @escaping (Error) -> Void)
        {
            _close()
            postCallback {
                self.queue.sync {
                    self.state = .closed
                }
                
                callbackHandler(error)
            }
        }
        
        private func postCallback(_ f: @escaping () -> Void) {
            callbackQueue.async {
                guard (self.queue.sync {
                    if self.state == .closed {
                        return false
                    }
                    return true
                }) else { return }
                
                f()
            }
        }
        
        private let queue: DispatchQueue
        private let callbackQueue: DispatchQueue
        private let connectTimeoutInterval: Double = 10.0
        
        private var state: State
        private var socket: RawDispatchSocket?
        private var _endPoint: SocketEndPoint?
        private var connectTask: ConnectTask?
        private var sendTask: SendTask?
        private var receiveTask: ReceiveTask?
        private var acceptTask: AcceptTask?
    }

    private enum State {
        case inited
        case connecting
        case connected
        case listening
        case closed
    }
    
    private class ConnectTask {
        public let nameResolveTask: NameResolveTask?
        public let endPoint: SocketEndPoint?
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
        
        public init(endPoint: SocketEndPoint,
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
        public var data: Data
        public var sentSize: Int
        public var successHandler: () -> Void
        public var errorHandler: (Error) -> Void
        
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
        public var maxSize: Int
        public var successHandler: (Data) -> Void
        public var errorHandler: (Error) -> Void
        
        public init(maxSize: Int,
                    successHandler: @escaping (Data) -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.maxSize = maxSize
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
    }
    
    private class AcceptTask {
        public var successHandler: (TCPSocket) -> Void
        public var errorHandler: (Error) -> Void
        
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
