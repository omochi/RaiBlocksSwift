import Foundation
import RaiBlocksPosix

public class DispatchSocket {
    public init(queue: DispatchQueue,
                fd: Int32,
                protocolFamily: ProtocolFamily) throws
    {
        self.queue = queue
        self.fd = fd
        self.protocolFamily = protocolFamily
        
        let st = Darwin.fcntl(fd, F_SETFL, O_NONBLOCK)
        if st == -1 {
            throw PosixError.init(errno: errno, message: "fcntl(\(fd), F_SETFL, O_NONBLOCK)")
        }
        
        self.readSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        self._readSuspended = true
        
        self.writeSource = DispatchSource.makeWriteSource(fileDescriptor: fd, queue: queue)
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
    
    public convenience init(queue: DispatchQueue,
                            protocolFamily: ProtocolFamily,
                            type: Int32) throws
    {
        let fd = Darwin.socket(protocolFamily.value, type, 0)
        if fd == -1 {
            throw PosixError.init(errno: errno, message: "socket()")
        }
        
        try self.init(queue: queue,
                      fd: fd,
                      protocolFamily: protocolFamily)
    }
    
    deinit {
        close()
    }

    public let fd: Int32
    public let protocolFamily: ProtocolFamily

    public func close() {
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
    
    public var readSuspended: Bool {
        return _readSuspended
    }
    
    public var writeSuspended: Bool {
        return _writeSuspended
    }
    
    public func getSockName() throws -> EndPoint {
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
    
    public func setSockOpt(level: Int32, name: Int32, value: CInt) throws {
        var value = value
        let st = Darwin.setsockopt(fd, level, name,
                                   UnsafeMutablePointer<CInt>(&value),
                                   UInt32(MemoryLayout<CInt>.size))
        if st == -1 {
            throw PosixError(errno: errno, message: "setsockopt(\(fd), \(level), \(name), \(value))")
        }
    }
    
    public func connect(endPoint: EndPoint) throws {
        precondition(endPoint.protocolFamily == protocolFamily)
        
        let st = endPoint.withSockAddrPointer { (p, size) in
            Darwin.connect(fd, p, UInt32(size))
        }
        if st == -1 {
            throw PosixError(errno: errno, message: "connect(\(fd), \(endPoint))")
        }
    }
     
    public func send(data: Data) throws -> Int {
        let st = data.withUnsafeBytes {
            Darwin.send(fd, $0, data.count, 0)
        }
        if st == -1 {
            throw PosixError(errno: errno, message: "send(\(fd), \(data.count))")
        }
        return st
    }

    public func recv(size: Int) throws -> Data {
        var chunk = Data(count: size)
        let st = chunk.withUnsafeMutableBytes {
            Darwin.recv(fd, $0, size, 0)
        }
        if st == -1 {
            throw PosixError(errno: errno, message: "recv(\(fd), \(size))")
        }
        chunk.count = st
        return chunk
    }
    
    public func bind(endPoint: EndPoint) throws {
        precondition(endPoint.protocolFamily == protocolFamily)
        
        let st = endPoint.withSockAddrPointer { (p, size) in
            Darwin.bind(fd, p, UInt32(size))
        }
        if st == -1 {
            throw PosixError(errno: errno, message: "bind(\(fd), \(endPoint))")
        }
    }

    public func listen(backlog: Int) throws {
        let st = Darwin.listen(fd, Int32(backlog))
        if st == -1 {
            throw PosixError(errno: errno, message: "listen(\(fd), \(backlog))")
        }
    }
    
    public func accept(queue: DispatchQueue) throws -> (DispatchSocket, EndPoint) {
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
        let socket = try DispatchSocket(queue: queue,
                                        fd: st,
                                        protocolFamily: protocolFamily)
        return (socket, endPoint)
    }
    
    public func sendTo(data: Data, endPoint: EndPoint) throws -> Int {
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
    
    public func recvFrom(size: Int) throws -> (Data, EndPoint) {
        var chunk = Data(count: size)
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
    
    public func awaitReadEvent(_ handler: @escaping () -> Void) {
        readHandler = handler
        _resumeRead()
    }
    
    public func awaitWriteEvent(_ handler: @escaping () -> Void) {
        writeHandler = handler
        _resumeWrite()
    }
    
//    public func setReadHandler(_ handler: @escaping () -> Void) {
//        readHandler = handler
//    }
//
//    public func setWriteHandler(_ handler: @escaping () -> Void) {
//        writeHandler = handler
//    }
//
//    public func resumeRead() {
//        _resumeRead()
//    }
//
//    public func suspendRead() {
//        _suspendRead()
//    }
//
//    public func resumeWrite() {
//        _resumeWrite()
//    }
//
//    public func suspendWrite() {
//        _suspendWrite()
//    }
    
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
        if self.closed || self._readSuspended { return }
        _suspendRead()
        self.readHandler?()
    }
    
    private func invokeWriteHandler() {
        if self.closed || self._writeSuspended { return }
        _suspendWrite()
        self.writeHandler?()
    }
    
    private let queue: DispatchQueue
    private let readSource: DispatchSourceRead
    private let writeSource: DispatchSourceWrite
    private var readHandler: (() -> Void)?
    private var writeHandler: (() -> Void)?
    private var _readSuspended: Bool
    private var _writeSuspended: Bool
    private var closed: Bool
}
