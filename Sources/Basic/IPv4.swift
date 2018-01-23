import Foundation

public enum IPv4 {
    public struct Address {
        public init(addr: in_addr) {
            self.addr = addr
        }
        
        public init() {
            self.init(addr: in_addr.init())
        }
        
        public let addr: in_addr
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

extension IPv4.Address : CustomStringConvertible {
    public var description: String {
        var addr = self.addr
        var data = Data.init(count: Int(INET_ADDRSTRLEN))
        let ret = data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<Int8>) in
            inet_ntop(PF_INET, &addr, p, UInt32(data.count))
        }
        assert(ret != nil)
        return String.init(data: data, encoding: .utf8)!
    }
}

extension IPv4.Address {
    public init?(string: String) {
        var addr = in_addr()
        let ret = inet_pton(PF_INET, string, &addr)
        if ret != 1 {
            return nil
        }
        self.init(addr: addr)
    }
}

extension IPv4.Address : Equatable {}

public func ==(a: IPv4.Address, b: IPv4.Address) -> Bool {
    return a.addr.s_addr == b.addr.s_addr
}

extension IPv4.EndPoint : CustomStringConvertible {
    public var description: String {
        return "\(address):\(port)"
    }
}

extension IPv4.EndPoint {
    public init(sockAddr: sockaddr_in) {
        self.init(address: IPv4.Address(addr: sockAddr.sin_addr),
                  port: Int(NSSwapBigShortToHost(sockAddr.sin_port)))
    }
    
    public func asSockAddr() -> sockaddr_in {
        return sockaddr_in.init(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                sin_family: UInt8(AF_INET),
                                sin_port: NSSwapHostShortToBig(UInt16(port)),
                                sin_addr: address.addr,
                                sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    }
}
