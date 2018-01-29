import Foundation

public enum SocketEndPoint {
    case ipv6(IPv6.EndPoint)
    case ipv4(IPv4.EndPoint)
}

extension SocketEndPoint {
    public var port: Int {
        get {
            switch self {
            case .ipv6(let ep):
                return ep.port
            case .ipv4(let ep):
                return ep.port
            }
        }
        set {
            switch self {
            case .ipv6(var ep):
                ep.port = newValue
                self = .ipv6(ep)
            case .ipv4(var ep):
                ep.port = newValue
                self = .ipv4(ep)
            }
        }
    }
}

extension SocketEndPoint : CustomStringConvertible {
    public var description: String {
        switch self {
        case .ipv6(let ep):
            return ep.description
        case .ipv4(let ep):
            return ep.description
        }
    }
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
    
    public init(protocolFamily: SocketProtocolFamily,
                sockAddr: UnsafePointer<sockaddr>)
    {
        switch protocolFamily {
        case .ipv6:
            let sockAddr = sockAddr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
            self = .ipv6(IPv6.EndPoint(sockAddr: sockAddr))
        case .ipv4:
            let sockAddr = sockAddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            self = .ipv4(IPv4.EndPoint(sockAddr: sockAddr))
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

