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
            print("read")
        }
        writeSource.setEventHandler {
            switch self.state {
            case .closed:
                return
            case .connecting:
                self.connectSuccess()
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
            
            connectTask?.close()
            connectTask = nil
            
            if readSuspended {
                readSource.resume()
                readSuspended = false
            }
            
            if writeSuspended {
                writeSource.resume()
                writeSuspended = false
            }
            
            let st = Darwin.close(socket)
            if st != 0 {
                fatalError(PosixError.init(errno: errno, message: "close").description)
            }
            
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
            writeSource.resume()
            writeSuspended = false
            
            let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timer.schedule(deadline: .now() + connectTimeoutInterval)
            timer.setEventHandler {
                self.connectFail(error: GenericError.init(message: "connect(\(endPoint)) timeout"))
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
                guard errno == EINPROGRESS else {
                    connectFail(error: PosixError.init(errno: errno, message: "connect(\(endPoint))"))
                    return
                }
            }
        }
    }
    
    public let socket: Int32
    
    private enum State {
        case inited
        case connecting
        case connected
        case closed
        case failed
    }
    
    private class ConnectTask {
        public var timer: DispatchSourceTimer
        public var successHandler: () -> Void
        public var errorHandler: (Error) -> Void

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
    
    private func connectSuccess() {
        precondition(state == .connecting)
        
        let task = connectTask!
        task.close()
        self.connectTask = nil
        
        writeSource.suspend()
        writeSuspended = true
        state = .connected
        
        postCallback {
            task.successHandler()
        }
    }
    
    private func connectFail(error: Error) {
        assert(state == .connecting)
        
        let task = connectTask!
        task.close()
        self.connectTask = nil
        
        writeSource.suspend()
        writeSuspended = true
        state = .failed
        
        postCallback {
            task.errorHandler(error)
        }
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
}
