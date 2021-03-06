import Foundation

public enum IPv4 {
    public struct Address {
        public init(addr: in_addr) {
            self.addr = addr
        }

        public let addr: in_addr
        
        public static let zero: Address = .init(addr: in_addr())
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

extension IPv4.Address : CustomStringConvertible {
    public var description: String {
        var addr = self.addr
        var data = Data.init(count: Int(INET_ADDRSTRLEN))
        let ret = data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<Int8>) in
            inet_ntop(PF_INET, &addr, p, UInt32(data.count))
        }
        assert(ret != nil)
        return String.init(cString: ret!)
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
    
    public func mapToV6() -> IPv6.Address {
        var addr = in6_addr.init()
        addr.__u6_addr.__u6_addr32 = (0, 0, UInt32(0x0000FFFF).convert(to: .big), self.addr.s_addr)
        return IPv6.Address(addr: addr)
    }
    
    public static var any: IPv4.Address {
        return IPv4.Address(addr: .init(s_addr: INADDR_ANY))
    }
}

extension IPv4.Address : Equatable {}

public func ==(a: IPv4.Address, b: IPv4.Address) -> Bool {
    return a.addr.s_addr == b.addr.s_addr
}

extension IPv4.Address : Comparable {}

public func <(a: IPv4.Address, b: IPv4.Address) -> Bool {
    return a.addr.s_addr.convert(from: .big) < b.addr.s_addr.convert(from: .big)
}

extension IPv4.EndPoint : CustomStringConvertible {
    public var description: String {
        return "\(address):\(port)"
    }
}

extension IPv4.Address : Hashable {
    public var hashValue: Int {
        var x = 1
        x = x &* 31 &+ addr.s_addr.hashValue
        return x
    }
}

extension IPv4.Address {
    public static let loopbackRange = IPv4.Address(string: "127.0.0.0")!...IPv4.Address(string: "127.255.255.255")!
    public static let multicastRange = IPv4.Address(string: "224.0.0.0")!...IPv4.Address(string: "239.255.255.255")!
}

extension IPv4.EndPoint : Equatable {}

public func ==(a: IPv4.EndPoint, b: IPv4.EndPoint) -> Bool {
    return a.address == b.address && a.port == b.port
}

extension IPv4.EndPoint : Hashable {
    public var hashValue: Int {
        var x = 1
        x = x &* 31 &+ address.hashValue
        x = x &* 31 &+ port.hashValue
        return x
    }
}

extension IPv4.EndPoint {
    public init(sockAddr: sockaddr_in) {
        self.init(address: IPv4.Address(addr: sockAddr.sin_addr),
                  port: Int(sockAddr.sin_port.convert(from: .big)))
    }
    
    public func asSockAddr() -> sockaddr_in {
        return sockaddr_in.init(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                sin_family: UInt8(AF_INET),
                                sin_port: UInt16(port).convert(to: .big),
                                sin_addr: address.addr,
                                sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    }
    
    public func mapToV6() -> IPv6.EndPoint {
        return IPv6.EndPoint(address: address.mapToV6(), port: port)
    }
    
    public static func listening(port: Int) -> IPv4.EndPoint {
        return IPv4.EndPoint(address: .any, port: port)
    }
}
