import Foundation

public enum SocketEndPoint {
    case ipv6(IPv6.EndPoint)
    case ipv4(IPv4.EndPoint)
}

extension SocketEndPoint {
    public var protocolFamily: SocketProtocolFamily {
        switch self {
        case .ipv6:
            return .ipv6
        case .ipv4:
            return .ipv4
        }
    }
    
    public func withSockAddrPointer<R>(_ f: (UnsafePointer<sockaddr>, Int) throws -> R) rethrows -> R {
        switch self {
        case .ipv6(let ep):
            var addr = ep.asSockAddr()
            return try UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
                try f(p, MemoryLayout.size(ofValue: addr))
            }
        case .ipv4(let ep):
            var addr = ep.asSockAddr()
            return try UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
                try f(p, MemoryLayout.size(ofValue: addr))
            }
        }
    }
    
    public mutating func withMutableSockAddrPointer<R>(_ f: (UnsafeMutablePointer<sockaddr>, Int) throws -> R) rethrows -> R {
        switch self {
        case .ipv6(let ep):
            var addr = ep.asSockAddr()
            return try UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
                try f(p, MemoryLayout.size(ofValue: addr))
            }
        case .ipv4(let ep):
            var addr = ep.asSockAddr()
            return try UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
                try f(p, MemoryLayout.size(ofValue: addr))
            }
        }
    }
}

