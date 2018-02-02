import Foundation

public enum IPv6 {
    public struct Address {
        public init(addr: in6_addr) {
            self.addr = addr
        }
        
        public let addr: in6_addr
        
        public static let zero: Address = .init(addr: in6_addr())
    }
    
    public struct EndPoint {
        public init(address: Address,
                    port: Int)
        {
            self.address = address
            self.port = port
        }
        
        public var address: Address
        public var port: Int
        
        public static let zero: EndPoint = .init(address: .zero, port: 0)
    }
}

extension IPv6.Address : CustomStringConvertible {
    public var description: String {
        var addr = self.addr
        var data = Data.init(count: Int(INET6_ADDRSTRLEN))
        let ret = data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<Int8>) in
            inet_ntop(PF_INET6, &addr, p, UInt32(data.count))
        }
        assert(ret != nil)
        return String.init(cString: ret!)
    }
}

extension IPv6.Address {
    public init?(string: String) {
        var addr = in6_addr()
        let ret = inet_pton(PF_INET6, string, &addr)
        if ret != 1 {
            return nil
        }
        self.init(addr: addr)
    }
    
    public var isMappedV4: Bool {
        return IPv6.Address.mappedV4Range.contains(self)
    }
    
    public var mappedV4: IPv4.Address? {
        guard isMappedV4 else {
            return nil
        }
        return IPv4.Address(addr: in_addr.init(s_addr: addr.__u6_addr.__u6_addr32.3))
    }
    
    public static var any: IPv6.Address {
        return IPv6.Address(addr: in6addr_any)
    }
}

extension IPv6.Address : Equatable {}

public func ==(a: IPv6.Address, b: IPv6.Address) -> Bool {
    return a.addr.__u6_addr.__u6_addr32 == b.addr.__u6_addr.__u6_addr32
}

extension IPv6.Address : Comparable {}

public func <(a: IPv6.Address, b: IPv6.Address) -> Bool {
    let ax = a.addr.__u6_addr.__u6_addr32
    let bx = b.addr.__u6_addr.__u6_addr32
    if ax.0.convert(from: .big) < bx.0.convert(from: .big) {
        return true
    }
    if ax.1.convert(from: .big) < bx.1.convert(from: .big) {
        return true
    }
    if ax.2.convert(from: .big) < bx.2.convert(from: .big) {
        return true
    }
    if ax.3.convert(from: .big) < bx.3.convert(from: .big) {
        return true
    }
    return false
}

extension IPv6.Address : Hashable {
    public var hashValue: Int {
        var x = 1
        x = x &* 31 &+ addr.__u6_addr.__u6_addr32.0.hashValue
        x = x &* 31 &+ addr.__u6_addr.__u6_addr32.1.hashValue
        x = x &* 31 &+ addr.__u6_addr.__u6_addr32.2.hashValue
        x = x &* 31 &+ addr.__u6_addr.__u6_addr32.3.hashValue
        return x
    }
}

extension IPv6.Address {
    public static let loopback = IPv6.Address(string: "::1")!
    public static let multicastRange = IPv6.Address(string: "FF00::")!...IPv6.Address(string: "FF00:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF")!
    public static let mappedV4Range = IPv6.Address(string: "::FFFF:0000:0000")!...IPv6.Address(string: "::FFFF:FFFF:FFFF")!
}

extension IPv6.EndPoint : CustomStringConvertible {
    public var description: String {
        return "[\(address)]:\(port)"
    }
}

extension IPv6.EndPoint : Equatable {}

public func ==(a: IPv6.EndPoint, b: IPv6.EndPoint) -> Bool {
    return a.address == b.address && a.port == b.port
}

extension IPv6.EndPoint : Hashable {
    public var hashValue: Int {
        var x = 1
        x = x &* 31 &+ address.hashValue
        x = x &* 31 &+ port.hashValue
        return x
    }
}

extension IPv6.EndPoint {
    public init(sockAddr: sockaddr_in6) {
        self.init(address: IPv6.Address(addr: sockAddr.sin6_addr),
                  port: Int(sockAddr.sin6_port.convert(from: .big)))
    }
    
    public func asSockAddr() -> sockaddr_in6 {
        return sockaddr_in6.init(sin6_len: UInt8(MemoryLayout<sockaddr_in6>.size),
                                 sin6_family: UInt8(AF_INET6),
                                 sin6_port: UInt16(port).convert(to: .big),
                                 sin6_flowinfo: 0,
                                 sin6_addr: address.addr,
                                 sin6_scope_id: 0)
    }
    
    public var isMappedV4: Bool {
        return address.isMappedV4
    }
    
    public var mappedV4: IPv4.EndPoint? {
        return address.mappedV4.map {
            IPv4.EndPoint(address: $0, port: port)
        }
    }
    
    public static func listening(port: Int) -> IPv6.EndPoint {
        return IPv6.EndPoint(address: .any, port: port)
    }
}
