import Foundation

public enum ProtocolFamily {
    case ipv6
    case ipv4
}

extension ProtocolFamily {
    public var value: Int32 {
        switch self {
        case .ipv6:
            return PF_INET6
        case .ipv4:
            return PF_INET
        }
    }
    
    public init?(value: Int32) {
        switch value {
        case PF_INET6:
            self = .ipv6
        case PF_INET:
            self = .ipv4
        default:
            return nil
        }
    }
}

extension ProtocolFamily : Equatable {}

public func ==(a: ProtocolFamily, b: ProtocolFamily) -> Bool {
    switch (a, b) {
    case (.ipv6, .ipv6): return true
    case (.ipv4, .ipv4): return true
    case (.ipv6, _): return false
    case (.ipv4, _): return false
    }
}
