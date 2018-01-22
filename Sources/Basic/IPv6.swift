import Foundation

public enum IPv6 {
    public struct Address {
        public init(addr: in6_addr) {
            self.addr = addr
        }

        public let addr: in6_addr
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
