import Foundation

public class RawDispatchSocket {
    public init(fd: Int32,
                protocolFamily: SocketProtocolFamily,
                queue: DispatchQueue) throws
    {
        self.fd = fd
        self.protocolFamily = protocolFamily
        self.queue = queue
        
        let st = Darwin.fcntl(fd, F_SETFL, O_NONBLOCK)
        if st == -1 {
            throw PosixError.init(errno: errno, message: "fcntl(\(fd), F_SETFL, O_NONBLOCK)")
        }
        
        self.readSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        self.readSuspended = true
        
        self.writeSource = DispatchSource.makeWriteSource(fileDescriptor: fd, queue: queue)
        self.writeSuspended = true
    }
    
    public convenience init(protocolFamily: SocketProtocolFamily,
                            type: Int32,
                            queue: DispatchQueue) throws
    {
        let fd = Darwin.socket(protocolFamily.value, type, 0)
        if fd == -1 {
            throw PosixError.init(errno: errno, message: "socket()")
        }
        try self.init(fd: fd,
                      protocolFamily: protocolFamily,
                      queue: queue)
    }

    public let fd: Int32
    public let protocolFamily: SocketProtocolFamily
    public private(set) var readSuspended: Bool
    public private(set) var writeSuspended: Bool
    
    public func close() {
        if readSuspended {
            resumeRead()
        }
        if writeSuspended {
            resumeWrite()
        }
        
        let st = Darwin.close(fd)
        if st == -1 {
            fatalError(PosixError.init(errno: errno, message: "close(\(fd))").description)
        }
    }
    
    public func setSockOpt(level: Int32, name: Int32, value: CInt) -> Int32 {
        var value = value
        return Darwin.setsockopt(fd, level, name, UnsafeMutablePointer<CInt>(&value), UInt32(MemoryLayout<CInt>.size))
    }
    
    public func connect(endPoint: SocketEndPoint) -> Int32 {
        return endPoint.withSockAddrPointer { (p, size) in
            Darwin.connect(fd, p, UInt32(size))
        }
    }
     
    public func send(data: UnsafeRawPointer, size: Int) -> Int {
        return Darwin.send(fd, data, size, 0)
    }
    
    public func recv(data: UnsafeMutableRawPointer, size: Int) -> Int {
        return Darwin.recv(fd, data, size, 0)
    }
    
    public func bind(endPoint: SocketEndPoint) -> Int32 {
        return endPoint.withSockAddrPointer { (p, size) in
            Darwin.bind(fd, p, UInt32(size))
        }
    }

    public func listen(backlog: Int) -> Int32 {
        return Darwin.listen(fd, Int32(backlog))
    }
    
    public func accept() -> (Int32, SocketEndPoint) {
        var endPoint: SocketEndPoint
        switch protocolFamily {
        case .ipv6:
            endPoint = .ipv6(.init())
        case .ipv4:
            endPoint = .ipv4(.init())
        }
        let st: Int32 = endPoint.withMutableSockAddrPointer { (p, size) in
            var size = UInt32(size)
            return Darwin.accept(fd, p, &size)
        }
        return (st, endPoint)
    }
    
    public func resumeRead() {
        precondition(readSuspended)
        readSource.resume()
        readSuspended = false
    }
    
    public func suspendRead() {
        precondition(!readSuspended)
        readSource.suspend()
        readSuspended = true
    }
    
    public func setReadHandler(_ handler: @escaping () -> Void) {
        readSource.setEventHandler(handler: handler)
    }
    
    public func resumeWrite() {
        precondition(writeSuspended)
        writeSource.resume()
        writeSuspended = false
    }
    
    public func suspendWrite() {
        precondition(!writeSuspended)
        writeSource.suspend()
        writeSuspended = true
    }
    
    public func setWriteHandler(_ handler: @escaping () -> Void) {
        writeSource.setEventHandler(handler: handler)
    }
    
    private let queue: DispatchQueue
    private let readSource: DispatchSourceRead
    private let writeSource: DispatchSourceWrite
}
