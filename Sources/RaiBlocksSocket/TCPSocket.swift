import Foundation
import RaiBlocksPosix
import RaiBlocksRandom

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
        public init(callbackQueue: DispatchQueue) throws {
            queue = DispatchQueue.init(label: "TCPSocket.Impl.queue")
            socket = nil
            _endPoint = nil
            self.callbackQueue = callbackQueue
            state = .inited
        }
        
        public var endPoint: EndPoint? {
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
        
        public func connect(protocolFamily: ProtocolFamily,
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
                
                func resolveHandler(endPoints: [EndPoint]) {
                    let task = task!
                    
                    do {
                        guard var endPoint = endPoints.getRandom() else {
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
        }
        
        public func connect(endPoint: EndPoint,
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
        
        public func receive(size: Int?,
                            successHandler: @escaping (Data) -> Void,
                            errorHandler: @escaping (Error) -> Void)
        {
            queue.sync {
                precondition(state == .connected)
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
        
        public func listen(protocolFamily: ProtocolFamily, port: Int, backlog: Int) throws {
            func body() throws {
                precondition(state == .inited)
                precondition(self.socket == nil)
                
                let socket = try initSocket {
                    try RawDispatchSocket(protocolFamily: protocolFamily,
                                          type: SOCK_STREAM,
                                          queue: queue)
                }
                
                try socket.setSockOpt(level: SOL_SOCKET, name: SO_REUSEADDR, value: 1)
                let endPoint: EndPoint = .listening(protocolFamily: protocolFamily, port: port)
                try socket.bind(endPoint: endPoint)
                try socket.listen(backlog: backlog)
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
        
        private func initSocket(_ socketFactory: () throws -> RawDispatchSocket) rethrows -> RawDispatchSocket {
            precondition(state == .inited || state == .connecting)
            precondition(self.socket == nil)
            
            let socket = try socketFactory()
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
            
            return socket
        }

        private func _connect(endPoint: EndPoint,
                              successHandler: @escaping () -> Void,
                              errorHandler: @escaping (Error) -> Void) throws {
            let socket = try initSocket {
                try RawDispatchSocket(protocolFamily: endPoint.protocolFamily,
                                      type: SOCK_STREAM,
                                      queue: queue)
            }
            assert(socket.writeSuspended)
            
            do {
                try socket.connect(endPoint: endPoint)
            } catch let e as PosixError {
                if e.errno != EINPROGRESS {
                    throw e
                }
            }
            
            socket.resumeWrite()
            
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
                return { task.successHandler() }
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
                        return
                    }
                    throw e
                }
                
                task.sentSize += sentSize
                if task.sentSize < task.data.count {
                    return
                }
                
                sendTask = nil
                socket.suspendWrite()
                postCallback {
                    return { task.successHandler() }
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
                socket.suspendRead()
                postCallback {
                    return { task.successHandler(task.data) }
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
                
                let (rawSocket, endPoint): (RawDispatchSocket, EndPoint)
                do {
                    (rawSocket, endPoint) = try socket.accept(queue: self.queue)
                } catch let e as PosixError {
                    if e.errno == EWOULDBLOCK {
                        return
                    }
                    throw e
                }

                let newSocketImpl = try Impl.init(callbackQueue: callbackQueue)
                let _ = newSocketImpl.initSocket { rawSocket }
                newSocketImpl._endPoint = endPoint
                newSocketImpl.state = .connected
                let newSocket = TCPSocket.init(impl: newSocketImpl)
                
                acceptTask = nil
                socket.suspendRead()
                
                postCallback {
                    return { task.successHandler(newSocket) }
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
                self.state = .closed
                return {
                    callbackHandler(error)
                }
            }
        }
        
        private func postCallback(_ f: @escaping () -> () -> Void) {
            callbackQueue.async {
                let next: () -> Void = self.queue.sync {
                    if self.state == .closed {
                        return {}
                    }
                    return f()
                }
                next()
            }
        }
        
        private let queue: DispatchQueue
        private let callbackQueue: DispatchQueue
        private let connectTimeoutInterval: Double = 10.0
        
        private var state: State
        private var socket: RawDispatchSocket?
        private var _endPoint: EndPoint?
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
