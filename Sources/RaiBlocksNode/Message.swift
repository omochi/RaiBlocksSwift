import Foundation
import RaiBlocksBasic
import RaiBlocksSocket

public enum Message {
    public enum Kind : UInt8, DataWritable, DataReadable {
        case invalid = 0
        case notAKind
        case keepalive
        case publish
        case confirmReq
        case confirmAck
        case bulkPull
        case bulkPush
        case accountRequest
        
        public init(from reader: DataReader) throws {
            let rawValue = try reader.read(UInt8.self)
            guard let x = Kind(rawValue: rawValue) else {
                throw GenericError(message: "invalid rawValue: \(rawValue)")
            }
            self = x
        }
        
        public func write(to writer: DataWriter) {
            writer.write(rawValue)
        }
    }
    
    public struct Header : DataWritable, DataReadable {
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
        
        public init(from reader: DataReader) throws {
            self.magicNumber = try reader.read(UInt16.self, from: .big)
            self.versionMax = try reader.read(UInt8.self)
            self.versionUsing = try reader.read(UInt8.self)
            self.versionMin = try reader.read(UInt8.self)
            self.kind = try reader.read(Kind.self)
            self.extensions = try reader.read(UInt16.self, from: .big)
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
        
        public var blockKind: Block.Kind? {
            get {
                let value = UInt8((extensions & Header.blockKindMask) >> 8)
                if value == 0 {
                    return nil
                }
                return Block.Kind(rawValue: value)!
            }
            set {
                extensions &= ~Header.blockKindMask
                extensions |= (UInt16(newValue?.rawValue ?? 0) << 8)
            }
        }
        
        public func write(to writer: DataWriter) {
            writer.write(magicNumber, byteOrder: .big)
            writer.write(versionMax)
            writer.write(versionUsing)
            writer.write(versionMin)
            writer.write(kind)
            writer.write(extensions, byteOrder: .big)
        }
        
        public static let ipv4OnlyBitIndex: Int = 1
        public static var ipv4OnlyMask: UInt16 {
            return UInt16(1) << Header.ipv4OnlyBitIndex
        }
        
        public static let blockKindMask: UInt16 = 0x0F00
    }
    
    public struct Keepalive : MessageProtocol {        
        public let endPoints: [IPv6.EndPoint]
        
        public let blockKind: Block.Kind? = nil
        
        public init(endPoints: [IPv6.EndPoint]) {
            self.endPoints = endPoints
            
            precondition(endPoints.count <= 8)
        }
        
        public init(from reader: DataReader) throws {
            var endPoints: [IPv6.EndPoint] = []
            for _ in 0..<8 {
                let endPoint = try reader.read(IPv6.EndPoint.self)
                endPoints.append(endPoint)
            }
            self.endPoints = endPoints
        }
        
        public func write(to writer: DataWriter) {
            let n = min(8, endPoints.count)
            for i in 0..<n {
                writer.write(endPoints[i])
            }
            for _ in n..<8 {
                writer.write(IPv6.EndPoint.zero)
            }
        }
        
        public static var kind: Message.Kind = .keepalive
    }
    
    public struct Publish : MessageProtocol {
        public let block: Block
        
        public var blockKind: Block.Kind? {
            return block.kind
        }
        
        public init(block: Block) {
            self.block = block
        }
        
        public init(from reader: DataReader, blockKind: Block.Kind) throws {
            self.block = try Block.init(from: reader, kind: blockKind)
        }
        
        public func write(to writer: DataWriter) {
            writer.write(block)
        }
        
        public static let kind: Message.Kind = .publish
    }
    
    public struct AccountRequest : MessageProtocol {
        public var start: Account.Address?
        public var age: UInt32
        public var count: UInt32
        
        public let blockKind: Block.Kind? = nil
        
        public init() {
            self.start = nil
            self.age = 0
            self.count = 0
        }
        
        public func write(to writer: DataWriter) {
            writer.write(start ?? .zero)
            writer.write(age, byteOrder: .little)
            writer.write(count, byteOrder: .little)
        }
        
        public static let kind: Message.Kind = .accountRequest
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





