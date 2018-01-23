import Foundation

public enum SocketProtocolFamily {
    case ipv6
    case ipv4
}

extension SocketProtocolFamily {
    public var value: Int32 {
        switch self {
        case .ipv6:
            return PF_INET6
        case .ipv4:
            return PF_INET
        }
    }
}
