import Foundation

public enum IPv6 {
    public struct Address {
        public init(addr: in6_addr) {
            self.addr = addr
        }
        
        public init() {
            self.init(addr: in6_addr.init())
        }

        public let addr: in6_addr
    }
    
    public struct EndPoint {
        public init(address: Address,
                    port: Int)
        {
            self.address = address
            self.port = port
        }
        
        public init() {
            self.init(address: .init(),
                      port: .init())
        }
        
        public var address: Address
        public var port: Int
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
        return String.init(data: data, encoding: .utf8)!
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
        guard addr.__u6_addr.__u6_addr32.0 == 0 else {
            return false
        }
        guard addr.__u6_addr.__u6_addr32.1 == 0 else {
            return false
        }
        guard addr.__u6_addr.__u6_addr32.2 == NSSwapHostIntToBig(0x0000FFFF) else {
            return false
        }
        return true
    }
    
    public var mappedV4: IPv4.Address? {
        guard isMappedV4 else {
            return nil
        }
        return IPv4.Address(addr: in_addr.init(s_addr: addr.__u6_addr.__u6_addr32.3))
    }
}

extension IPv6.Address : Equatable {}

public func ==(a: IPv6.Address, b: IPv6.Address) -> Bool {
    return a.addr.__u6_addr.__u6_addr32 == b.addr.__u6_addr.__u6_addr32
}

extension IPv6.EndPoint : CustomStringConvertible {
    public var description: String {
        return "[\(address)]:\(port)"
    }
}

extension IPv6.EndPoint {
    public init(sockAddr: sockaddr_in6) {
        self.init(address: IPv6.Address(addr: sockAddr.sin6_addr),
                  port: Int(NSSwapBigShortToHost(sockAddr.sin6_port)))
    }
    
    public func asSockAddr() -> sockaddr_in6 {
        return sockaddr_in6.init(sin6_len: UInt8(MemoryLayout<sockaddr_in6>.size),
                                 sin6_family: UInt8(AF_INET6),
                                 sin6_port: NSSwapHostShortToBig(UInt16(port)),
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
}
