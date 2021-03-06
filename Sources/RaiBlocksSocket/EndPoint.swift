import Foundation

public enum EndPoint {
    case ipv6(IPv6.EndPoint)
    case ipv4(IPv4.EndPoint)
}

extension EndPoint {
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

extension EndPoint : CustomStringConvertible {
    public var description: String {
        switch self {
        case .ipv6(let ep):
            return ep.description
        case .ipv4(let ep):
            return ep.description
        }
    }
}

extension EndPoint : Equatable {}

public func ==(a: EndPoint, b: EndPoint) -> Bool {
    switch (a, b) {
    case (.ipv6(let epa), .ipv6(let epb)):
        return epa == epb
    case (.ipv4(let epa), .ipv4(let epb)):
        return epa == epb
    case (.ipv6, _):
        return false
    case (.ipv4, _):
        return false
    }
}

extension EndPoint : Hashable {
    public var hashValue: Int {
        var x: Int
        switch self {
        case .ipv4(let ep):
            x = 1
            x = x &* 31 &+ ep.hashValue
        case .ipv6(let ep):
            x = 2
            x = x &* 31 &+ ep.hashValue
        }
        return x
    }
}

extension EndPoint {
    public var protocolFamily: ProtocolFamily {
        switch self {
        case .ipv6: return .ipv6
        case .ipv4: return .ipv4
        }
    }
    
    public init(protocolFamily: ProtocolFamily,
                sockAddr: UnsafePointer<sockaddr>)
    {
        switch protocolFamily {
        case .ipv6:
            let sockAddr = sockAddr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
            self = .ipv6(.init(sockAddr: sockAddr))
        case .ipv4:
            let sockAddr = sockAddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            self = .ipv4(.init(sockAddr: sockAddr))
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
        let ret: R
        switch self {
        case .ipv6(let ep):
            var addr = ep.asSockAddr()
            ret = try UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
                try f(p, MemoryLayout.size(ofValue: addr))
            }
            self = .ipv6(.init(sockAddr: addr))
        case .ipv4(let ep):
            var addr = ep.asSockAddr()
            ret = try UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
                try f(p, MemoryLayout.size(ofValue: addr))
            }
            self = .ipv4(.init(sockAddr: addr))
        }
        return ret
    }
    
    public func toV4() throws -> IPv4.EndPoint {
        switch self {
        case .ipv6(let ep):
            guard let v4 = ep.mappedV4 else {
                throw SocketError(message: "it can not be converted to IPv4: \(ep)")
            }
            return v4
        case .ipv4(let ep): return ep
        }
    }
    
    public func toV6() -> IPv6.EndPoint {
        switch self {
        case .ipv6(let ep): return ep
        case .ipv4(let ep): return ep.mapToV6()
        }
    }
    
    public static func zero(protocolFamily: ProtocolFamily) -> EndPoint {
        switch protocolFamily {
        case .ipv6: return .ipv6(.zero)
        case .ipv4: return .ipv4(.zero)
        }
    }
    
    public static func listening(protocolFamily: ProtocolFamily, port: Int) -> EndPoint {
        switch protocolFamily {
        case .ipv6: return .ipv6(.listening(port: port))
        case .ipv4: return .ipv4(.listening(port: port))
        }
    }
}

