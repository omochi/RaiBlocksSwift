//
//  TCPSocket.swift
//  Basic
//
//  Created by omochimetaru on 2018/01/22.
//

import Foundation

public class TCPSocket {
    public init(callbackQueue: DispatchQueue) throws {
        let socket = Darwin.socket(PF_INET6, SOCK_STREAM, 0)
        if socket == -1 {
            throw PosixError.init(errno: errno, message: "socket()")
        }
        
        self.socket = socket
        
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
        
        state = .inited
        
        readSource.setEventHandler {
            switch self.state {
            case .connected:
                self.doReceive()
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
        queue.sync {
            precondition(state == .inited)
            precondition(writeSuspended)
            
            resumeWrite()
            
            let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timer.schedule(deadline: .now() + connectTimeoutInterval)
            timer.setEventHandler {
                self.doConnectError(error: GenericError.init(message: "connect(\(endPoint)) timeout"))
            }
            timer.resume()
            let task = ConnectTask.init(timer: timer,
                                        successHandler: successHandler,
                                        errorHandler: errorHandler)
            connectTask = task
            state = .connecting
            
            var sockAddr = endPoint.asSockAddr()
            let st = UnsafeMutablePointer(&sockAddr)
                .withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddr in
                    Darwin.connect(socket, sockAddr, UInt32(MemoryLayout<sockaddr_in6>.size))
            }
            if st != 0 {
                if errno != EINPROGRESS {
                    doConnectError(error: PosixError.init(errno: errno, message: "connect(\(endPoint))"))
                    return
                }
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
    
    public let socket: Int32
    
    private enum State {
        case inited
        case connecting
        case connected
        case closed
        case error
    }
    
    private class ConnectTask {
        public let timer: DispatchSourceTimer
        public let successHandler: () -> Void
        public let errorHandler: (Error) -> Void

        public init(timer: DispatchSourceTimer,
                    successHandler: @escaping () -> Void,
                    errorHandler: @escaping (Error) -> Void)
        {
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
    
    private func doConnectSuccess() {
        assert(state == .connecting)
        
        let task = connectTask!
        task.close()
        self.connectTask = nil
        
        suspendWrite()
        state = .connected
        
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
        connectTask?.close()
        connectTask = nil
        
        receiveTask = nil
        sendTask = nil
        
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
        
        let st = task.data.withUnsafeBytes { p in
            Darwin.send(socket, p + task.sentSize, task.data.count - task.sentSize, 0)
        }
        if st == -1 {
            if errno == EAGAIN {
                return
            }
            
            doError(error: PosixError.init(errno: errno, message: "send()"),
                    callbackHandler: task.errorHandler)
            return
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
    
    private func doReceive() {
        let task = receiveTask!
        
        var data = Data.init()
        
        while true {
            var chunk = Data.init(count: 1024)
            let st = chunk.withUnsafeMutableBytes { p in
                Darwin.recv(socket, p, chunk.count, 0)
            }
            if st == -1 {
                if errno == EAGAIN {
                    print("EAGAIN")
                    break
                }
                
                doError(error: PosixError.init(errno: errno, message: "read()"),
                        callbackHandler: task.errorHandler)
                return
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
}
