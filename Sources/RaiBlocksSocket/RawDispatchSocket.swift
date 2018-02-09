import Foundation
import RaiBlocksPosix

public class RawDispatchSocket {
    public init(fd: Int32,
                protocolFamily: ProtocolFamily,
                callbackQueue: DispatchQueue) throws
    {
        self.syncQueue = DispatchQueue(label: "DispatchSocket.syncQueue")
        self.fd = fd
        self.protocolFamily = protocolFamily
        self.callbackQueue = callbackQueue
        
        let st = Darwin.fcntl(fd, F_SETFL, O_NONBLOCK)
        if st == -1 {
            throw PosixError.init(errno: errno, message: "fcntl(\(fd), F_SETFL, O_NONBLOCK)")
        }
        
        self.readSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: syncQueue)
        self._readSuspended = true
        
        self.writeSource = DispatchSource.makeWriteSource(fileDescriptor: fd, queue: syncQueue)
        self._writeSuspended = true
        
        self.closed = false
        
        weak var wself = self
        
        readSource.setEventHandler {
            wself?.invokeReadHandler()
        }
        
        writeSource.setEventHandler {
            wself?.invokeWriteHandler()
        }
    }
    
    public convenience init(protocolFamily: ProtocolFamily,
                            type: Int32,
                            callbackQueue: DispatchQueue) throws
    {
        let fd = Darwin.socket(protocolFamily.value, type, 0)
        if fd == -1 {
            throw PosixError.init(errno: errno, message: "socket()")
        }
        
        try self.init(fd: fd,
                      protocolFamily: protocolFamily,
                      callbackQueue: callbackQueue)
    }
    
    deinit {
        close()
    }

    public let fd: Int32
    public let protocolFamily: ProtocolFamily
    public let callbackQueue: DispatchQueue

    public func close() {
        syncQueue.sync {
            if closed { return }
            
            if _readSuspended {
                _resumeRead()
            }
            if _writeSuspended {
                _resumeWrite()
            }
            
            let st = Darwin.close(fd)
            if st == -1 {
                fatalError(PosixError(errno: errno, message: "close(\(fd))").description)
            }
            
            closed = true
        }
    }
    
    public var readSuspended: Bool {
        return syncQueue.sync { _readSuspended }
    }
    
    public var writeSuspended: Bool {
        return syncQueue.sync { _writeSuspended }
    }
    
    public func getSockName() throws -> EndPoint {
        return try syncQueue.sync {
            var endPoint = EndPoint.zero(protocolFamily: protocolFamily)
            try endPoint.withMutableSockAddrPointer { (addr, size) in
                var tempSize = UInt32(size)
                let st = Darwin.getsockname(fd, addr, &tempSize)
                if st == -1 {
                    throw PosixError(errno: errno, message: "getsockname(\(fd))")
                }
                assert(tempSize == UInt32(size))
            }
            return endPoint
        }
    }
    
    public func setSockOpt(level: Int32, name: Int32, value: CInt) throws {
        try syncQueue.sync {
            var value = value
            let st = Darwin.setsockopt(fd, level, name,
                                       UnsafeMutablePointer<CInt>(&value),
                                       UInt32(MemoryLayout<CInt>.size))
            if st == -1 {
                throw PosixError(errno: errno, message: "setsockopt(\(fd), \(level), \(name), \(value))")
            }
        }
    }
    
    public func connect(endPoint: EndPoint) throws {
        try syncQueue.sync {
            precondition(endPoint.protocolFamily == protocolFamily)
            
            let st = endPoint.withSockAddrPointer { (p, size) in
                Darwin.connect(fd, p, UInt32(size))
            }
            if st == -1 {
                throw PosixError(errno: errno, message: "connect(\(fd), \(endPoint))")
            }
        }
    }
     
    public func send(data: Data) throws -> Int {
        return try syncQueue.sync {
            let st = data.withUnsafeBytes {
                Darwin.send(fd, $0, data.count, 0)
            }
            if st == -1 {
                throw PosixError(errno: errno, message: "send(\(fd), \(data.count))")
            }
            return st
        }
    }

    public func recv(size: Int) throws -> Data {
        return try syncQueue.sync {
            var chunk = Data.init(count: size)
            let st = chunk.withUnsafeMutableBytes {
                Darwin.recv(fd, $0, size, 0)
            }
            if st == -1 {
                throw PosixError(errno: errno, message: "recv(\(fd), \(size))")
            }
            chunk.count = st
            return chunk
        }
    }
    
    public func bind(endPoint: EndPoint) throws {
        return try syncQueue.sync {
            precondition(endPoint.protocolFamily == protocolFamily)
            
            let st = endPoint.withSockAddrPointer { (p, size) in
                Darwin.bind(fd, p, UInt32(size))
            }
            if st == -1 {
                throw PosixError(errno: errno, message: "bind(\(fd), \(endPoint))")
            }
        }
    }

    public func listen(backlog: Int) throws {
        return try syncQueue.sync {
            let st = Darwin.listen(fd, Int32(backlog))
            if st == -1 {
                throw PosixError(errno: errno, message: "listen(\(fd), \(backlog))")
            }
        }
    }
    
    public func accept(queue: DispatchQueue) throws -> (RawDispatchSocket, EndPoint) {
        return try syncQueue.sync {
            var endPoint = EndPoint.zero(protocolFamily: protocolFamily)
            let st: Int32 = try endPoint.withMutableSockAddrPointer { (addr, size) in
                var tempSize = UInt32(size)
                let st = Darwin.accept(fd, addr, &tempSize)
                if st == -1 {
                    throw PosixError(errno: errno, message: "accept(\(fd))")
                }
                assert(tempSize == UInt32(size))
                return st
            }
            let socket = try RawDispatchSocket(fd: st,
                                               protocolFamily: protocolFamily,
                                               callbackQueue: callbackQueue)
            return (socket, endPoint)
        }
    }
    
    public func sendTo(data: Data, endPoint: EndPoint) throws -> Int {
        return try syncQueue.sync {
            precondition(endPoint.protocolFamily == protocolFamily)
            
            let st = data.withUnsafeBytes { (p: UnsafePointer<UInt8>) -> Int in
                return endPoint.withSockAddrPointer { (addr, size) -> Int in
                    return Darwin.sendto(fd, p, data.count, 0, addr, UInt32(size))
                }
            }
            if st == -1 {
                throw PosixError(errno: errno, message: "sendto(\(fd), \(data.count), 0, \(endPoint))")
            }
            return st
        }
    }
    
    public func recvFrom(size: Int) throws -> (Data, EndPoint) {
        return try syncQueue.sync {
            var chunk = Data.init(count: size)
            var endPoint = EndPoint.zero(protocolFamily: protocolFamily)
            let st: Int = try endPoint.withMutableSockAddrPointer { (addr, addrSize) in
                try chunk.withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt8>) in
                    var tempAddrSize = UInt32(addrSize)
                    let st = Darwin.recvfrom(fd, p, size, 0, addr, &tempAddrSize)
                    if st == -1 {
                        throw PosixError(errno: errno, message: "recvfrom(\(fd), \(size))")
                    }
                    assert(tempAddrSize == UInt32(addrSize))
                    return st
                }
            }
            chunk.count = st
            return (chunk, endPoint)
        }
    }
    
    public func setReadHandler(_ handler: @escaping () -> Void) {
        syncQueue.sync {
            readHandler = handler
        }
    }
    
    public func setWriteHandler(_ handler: @escaping () -> Void) {
        syncQueue.sync {
            writeHandler = handler
        }
    }
    
    public func resumeRead() {
        syncQueue.sync {
            _resumeRead()
        }
    }
    
    public func suspendRead() {
        syncQueue.sync {
            _suspendRead()
        }
    }
    
    public func resumeWrite() {
        syncQueue.sync {
            _resumeWrite()
        }
    }
    
    public func suspendWrite() {
        syncQueue.sync {
            _suspendWrite()
        }
    }
    
    private func _resumeRead() {
        precondition(_readSuspended)
        readSource.resume()
        _readSuspended = false
    }
    
    private func _suspendRead() {
        precondition(!_readSuspended)
        readSource.suspend()
        _readSuspended = true
    }
    
    private func _resumeWrite() {
        precondition(_writeSuspended)
        writeSource.resume()
        _writeSuspended = false
    }
    
    private func _suspendWrite() {
        precondition(!_writeSuspended)
        writeSource.suspend()
        _writeSuspended = true
    }
    
    private func invokeReadHandler() {
        weak var wself = self
        
        callbackQueue.async {
            guard let `self` = wself else { return }
            
            let f: (() -> Void)? = self.syncQueue.sync {
                if self.closed || self._readSuspended { return nil }
                return { self.readHandler?() }
            }
            f?()
        }
    }

    private func invokeWriteHandler() {
        weak var wself = self
        
        callbackQueue.async {
            guard let `self` = wself else { return }
            
            let f: (() -> Void)? = self.syncQueue.sync {
                if self.closed || self._writeSuspended { return nil }
                return { self.writeHandler?() }
            }
            f?()
        }
    }
    
    private let syncQueue: DispatchQueue
    private let readSource: DispatchSourceRead
    private let writeSource: DispatchSourceWrite
    private var readHandler: (() -> Void)?
    private var writeHandler: (() -> Void)?
    private var _readSuspended: Bool
    private var _writeSuspended: Bool
    private var closed: Bool
}
