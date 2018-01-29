import Foundation
import RaiBlocksBasic

public enum Message {
    public enum Kind : UInt8, DataWritable {
        case invalid = 0
        case notAKind
        case keepAlive
        case publish
        case confirmReq
        case confirmAck
        case bulkPull
        case bulkPush
        case accountRequest
        
        public func write(to writer: DataWriter) {
            writer.write(rawValue)
        }
    }
    
    public struct Header : DataWritable {
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
            writer.write(magicNumber)
            writer.write(versionMax)
            writer.write(versionUsing)
            writer.write(versionMin)
            writer.write(kind)
            writer.write(extensions)
        }
        
        public static let ipv4OnlyBitIndex: Int = 1
        public static var ipv4OnlyMask: UInt16 {
            return UInt16(1) << Header.ipv4OnlyBitIndex
        }
        
        public static let blockKindMask: UInt16 = 0x0F00
    }
    
    public struct AccountRequest : DataWritable {
        public var header: Header
        public var start: Account.Address?
        public var age: UInt32
        public var count: UInt32
        
        public init() {
            self.header = .init(kind: .accountRequest)
            self.start = nil
            self.age = 0
            self.count = 0
        }
        
        public func write(to writer: DataWriter) {
            writer.write(header)
            writer.write(start ?? .zero)
            writer.write(NSSwapHostIntToBig(age))
            writer.write(NSSwapHostIntToBig(count))
        }
    }
    
    public struct AccountResponseEntry : DataReadable {
        public var account: Account.Address?
        public var headBlock: Block.Hash?
        
        public init(from reader: DataReader) throws {
            account = try Account.Address(from: reader)
            if account == .zero {
                account = nil
            }
            
            headBlock = try Block.Hash(from: reader)
            if headBlock == .zero {
                headBlock = nil
            }
        }
    }
}





