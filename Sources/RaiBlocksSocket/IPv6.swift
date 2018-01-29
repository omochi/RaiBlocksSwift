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
}
