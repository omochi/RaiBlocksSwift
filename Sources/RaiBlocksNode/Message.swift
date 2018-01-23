import Foundation
import RaiBlocksBasic

public enum Message {
    public enum Kind : UInt8 {
        case invalid = 0
        case notAKind
        case keepAlive
        case publish
        case confirmReq
        case confirmAck
        case bulkPull
        case bulkPush
        case accountRequest
    }
    
    public struct Header {
        public var magicNumber: UInt16
        public var versionMax: UInt8
        public var versionUsing: UInt8
        public var versionMin: UInt8
        public var kind: Kind
        public var extensions: UInt16
        
        public init(kind: Kind) {
            self.magicNumber = UInt16(Unicode.Scalar("R")!.value) << 8 |
                UInt16(Unicode.Scalar("C")!.value)
            self.versionMax = 5
            self.versionUsing = 5
            self.versionMin = 5
            self.kind = kind
            self.extensions = 0
        }
        
        public var ipv4Only: Bool {
            get {
                return (extensions & Header.ipv4OnlyMask) != 0
            }
            set {
                if newValue {
                    extensions |= Header.ipv4OnlyMask
                } else {
                    extensions &= ~Header.ipv4OnlyMask
                }
            }
        }
        
        public var blockKind: Block.Kind {
            get {
                let value = (extensions & Header.blockKindMask) >> 8
                return Block.Kind(rawValue: UInt8(value))!
            }
            set {
                extensions &= ~Header.blockKindMask
                extensions |= (UInt16(newValue.rawValue) << 8)
            }
        }
        
        public func write(to writer: DataWriter) {
        }
        
        public static let ipv4OnlyBitIndex: Int = 1
        public static var ipv4OnlyMask: UInt16 {
            return UInt16(1) << Header.ipv4OnlyBitIndex
        }
        
        public static let blockKindMask: UInt16 = 0x0F00
    }
    
    public struct AccountRequest {
        public var header: Header
        public var start: Account.Address
        public var age: UInt32
        public var count: UInt32
        
        public init() {
            self.header = .init(kind: .accountRequest)
            self.start = .init()
            self.age = 0
            self.count = 0
        }
    }
}





