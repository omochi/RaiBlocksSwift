//
//  TCPSocket.swift
//  Basic
//
//  Created by omochimetaru on 2018/01/22.
//

import Foundation

public class TCPSocket {
    public convenience init(callbackQueue: DispatchQueue) throws {
        let socket = Darwin.socket(PF_INET6, SOCK_STREAM, 0)
        if socket == -1 {
            throw PosixError.init(errno: errno, message: "socket()")
        }
        
        try self.init(socket: socket,
                      endPoint: nil,
                      callbackQueue: callbackQueue)
    }
    
    public let socket: Int32
    public private(set) var endPoint: IPv6.EndPoint?
    
    deinit {
        close()
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
    
    public func connect(endPoint: IPv6.EndPoint,
                        successHandler: @escaping () -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        func body() throws {
            precondition(state == .inited)
            assert(writeSuspended)
            
            var sockAddr = endPoint.asSockAddr()
            let st = UnsafeMutablePointer(&sockAddr)
                .withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddr in
                    Darwin.connect(socket, sockAddr, UInt32(MemoryLayout<sockaddr_in6>.size))
            }
            if st != 0 {
                if errno != EINPROGRESS {
                    throw PosixError.init(errno: errno, message: "connect(\(endPoint))")
                }
            }
            
            resumeWrite()
            
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
        
        queue.sync {
            do {
                try body()
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
            precondition(writeSuspended)
            precondition(sendTask == nil)
            
            resumeWrite()
            
            let task = SendTask.init(data: data,
                                     successHandler: successHandler,
                                     errorHandler: errorHandler)
            sendTask = task
        }
    }
    
    public func receive(successHandler: @escaping (Data) -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        queue.sync {
            precondition(state == .connected)
            precondition(readSuspended)
            precondition(receiveTask == nil)
            
            resumeRead()
            
            let task = ReceiveTask.init(successHandler: successHandler,
                                        errorHandler: errorHandler)
            receiveTask = task
        }
    }
    
    public func listen(port: Int, backlog: Int = 8) throws {
        func body() throws {
            precondition(state == .inited)
            
            var intValue: CInt = 1
            
            var st = Darwin.setsockopt(socket, SOL_SOCKET, SO_REUSEADDR,
                                       UnsafeMutablePointer(&intValue),
                                       UInt32(MemoryLayout<CInt>.size))
            if st != 0 {
                throw PosixError.init(errno: errno, message: "setsockopt(SO_REUSEADDR)")
            }
            
            var sockAddr = sockaddr_in6.init(sin6_len: UInt8(MemoryLayout<sockaddr_in6>.size),
                                             sin6_family: UInt8(AF_INET6),
                                             sin6_port: NSSwapHostShortToBig(UInt16(port)),
                                             sin6_flowinfo: 0,
                                             sin6_addr: in6addr_any,
                                             sin6_scope_id: 0)
            st = UnsafeMutablePointer(&sockAddr).withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddr in
                Darwin.bind(socket, sockAddr, UInt32(MemoryLayout<sockaddr_in6>.size))
            }
            if st != 0 {
                throw PosixError.init(errno: errno, message: "bind(\(port))")
            }
            
            st = Darwin.listen(socket, Int32(backlog))
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
                state = .error
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
            
            let task = AcceptTask.init(successHandler: successHandler,
                                       errorHandler: errorHandler)
            acceptTask = task
            resumeRead()
        }
    }

    private enum State {
        case inited
        case connecting
        case connected
        case listening
        case closed
        case error
    }
    
    private class ConnectTask {
        public let endPoint: IPv6.EndPoint
        public let timer: DispatchSourceTimer
        public let successHandler: () -> Void
        public let errorHandler: (Error) -> Void

        public init(endPoint: IPv6.EndPoint,
                    timer: DispatchSourceTimer,
                    successHandler: @escaping () -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
            self.endPoint = endPoint
            self.timer = timer
            self.successHandler = successHandler
            self.errorHandler = errorHandler
        }
        
        public func close() {
            timer.cancel()
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
        public var successHandler: (Data) -> Void
        public var errorHandler: (Error) -> Void
        
        public init(successHandler: @escaping (Data) -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
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
    
    private init(socket: Int32,
                 endPoint: IPv6.EndPoint?,
                 callbackQueue: DispatchQueue) throws
    {
        self.socket = socket
        self.endPoint = endPoint
        
        let st = fcntl(socket, F_SETFL, O_NONBLOCK)
        if st == -1 {
            throw PosixError.init(errno: errno, message: "fcntl(F_SETFL, O_NONBLOCK)")
        }
        
        queue = DispatchQueue.init(label: "TCPSocket.queue")
        self.callbackQueue = callbackQueue
        
        readSource = DispatchSource.makeReadSource(fileDescriptor: socket, queue: queue)
        readSuspended = true
        
        writeSource = DispatchSource.makeWriteSource(fileDescriptor: socket, queue: queue)
        writeSuspended = true
        
        if endPoint == nil {
            state = .inited
        } else {
            state = .connected
        }
        
        readSource.setEventHandler {
            switch self.state {
            case .connected:
                self.doReceive()
            case .listening:
                self.doAccept()
            default:
                return
            }
        }
        
        writeSource.setEventHandler {
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
    
    private func doConnectSuccess() {
        assert(state == .connecting)
        
        suspendWrite()
        
        let task = connectTask!
        task.close()
        connectTask = nil
        
        state = .connected
        endPoint = task.endPoint
        
        postCallback {
            task.successHandler()
        }
    }
    
    private func doConnectError(error: Error) {
        assert(state == .connecting)
        
        let task = connectTask!
        doError(error: error, callbackHandler: task.errorHandler)
    }
    
    private func doError(error: Error,
                         callbackHandler: @escaping (Error) -> Void)
    {
        _close()
        state = .error
        postCallback {
            callbackHandler(error)
        }
    }
    
    private func _close() {
        endPoint = nil
        
        connectTask?.close()
        connectTask = nil
        
        receiveTask = nil
        sendTask = nil
        acceptTask = nil
        
        if readSuspended {
            resumeRead()
        }
        if writeSuspended {
            resumeWrite()
        }
        
        let st = Darwin.close(socket)
        if st != 0 {
            fatalError(PosixError.init(errno: errno, message: "close()").description)
        }
    }
    
    private func doSend() {
        let task = sendTask!
        
        func body() throws {
            let st = task.data.withUnsafeBytes { p in
                Darwin.send(socket, p + task.sentSize, task.data.count - task.sentSize, 0)
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
            suspendWrite()
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
            var data = Data.init()
            
            while true {
                var chunk = Data.init(count: 1024)
                let st = chunk.withUnsafeMutableBytes { p in
                    Darwin.recv(socket, p, chunk.count, 0)
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
            suspendRead()
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
            var sockAddr = sockaddr_in6.init()
            var sockAddrSize = UInt32(MemoryLayout<sockaddr_in6>.size)
            let st = UnsafeMutablePointer(&sockAddr).withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddr in
                Darwin.accept(socket, sockAddr, UnsafeMutablePointer(&sockAddrSize))                
            }
            if st == -1 {
                if errno == EWOULDBLOCK {
                    return
                }
                
                throw PosixError.init(errno: errno, message: "accept()")
            }
            
            let newSocket = try TCPSocket.init(socket: st,
                                               endPoint: IPv6.EndPoint.init(sockAddr: sockAddr),
                                               callbackQueue: callbackQueue)
            
            acceptTask = nil
            suspendRead()
            
            postCallback {
                task.successHandler(newSocket)
            }
        }
        
        do {
            try body()
        } catch let error {
            doError(error: error, callbackHandler: task.errorHandler)
        }
    }
    
    private func resumeRead() {
        readSource.resume()
        readSuspended = false
    }
    
    private func suspendRead() {
        readSource.suspend()
        readSuspended = true
    }
    
    private func resumeWrite() {
        writeSource.resume()
        writeSuspended = false
    }
    
    private func suspendWrite() {
        writeSource.suspend()
        writeSuspended = true
    }
    
    private func postCallback(_ f: @escaping () -> Void) {
        callbackQueue.async {
            let closed = self.queue.sync { self.state == .closed }
            if closed {
                return
            }
            
            f()
        }
    }
    
    private let queue: DispatchQueue
    private let callbackQueue: DispatchQueue
    private let readSource: DispatchSourceRead
    private var readSuspended: Bool
    private let writeSource: DispatchSourceWrite
    private var writeSuspended: Bool
    private let connectTimeoutInterval: Double = 10.0

    private var state: State
    private var connectTask: ConnectTask?
    private var sendTask: SendTask?
    private var receiveTask: ReceiveTask?
    private var acceptTask: AcceptTask?
}
