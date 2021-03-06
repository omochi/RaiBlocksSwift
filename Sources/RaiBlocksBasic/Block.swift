import Foundation
import SQLite

public enum Block {
    public struct Hash : DataConvertible, DataWritable, DataReadable {
        public init(data: Data) {
            precondition(data.count == Hash.size)
            
            self._data = data
        }

        public init(from reader: DataReader) throws {
            let data = try reader.read(Data.self, size: Hash.size)
            self.init(data: data)
        }
        
        public func write(to writer: DataWriter) {
            writer.write(_data)
        }
        
        public func asData() -> Data {
            return _data
        }
        
        public static let size: Int = 32
        
        public static let zero: Hash = .init(data: Data.init(count: size))
        
        private let _data: Data
    }
    
    public enum Kind : UInt8, CustomStringConvertible {
        case invalid = 0
        case notABlock = 1
        case send = 2
        case receive = 3
        case open = 4
        case change = 5
        
        public var description: String {
            switch self {
            case .invalid: return "invalid"
            case .notABlock: return "notABlock"
            case .send: return "send"
            case .receive: return "receive"
            case .open: return "open"
            case .change: return "change"
            }
        }
    }
    
    public struct Send : BlockProtocol {
        public var previous: Block.Hash
        public var destination: Account.Address
        public var balance: Amount
        public var signature: Signature?
        public var work: Work?
        
        public init(previous: Block.Hash,
                    destination: Account.Address,
                    balance: Amount,
                    signature: Signature? = nil,
                    work: Work? = nil)
        {
            self.previous = previous
            self.destination = destination
            self.balance = balance
            self.signature = signature
            self.work = work
        }
        
        public init(from reader: DataReader) throws {
            previous = try reader.read(Block.Hash.self)
            destination = try reader.read(Account.Address.self)
            balance = try reader.read(Amount.self)
            try self.readSuffix(from: reader)
        }
        
        public var description: String {
            let fields = [
                "hash=\(hash)",
                "previous=\(previous)",
                "destination=\(destination)",
                "balance=\(balance)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Send(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: previous.asData())
            blake.update(data: destination.asData())
            blake.update(data: balance.asData())
        }
        
        public func write(to writer: DataWriter) {
            writer.write(previous)
            writer.write(destination)
            writer.write(balance)
            writeSuffix(to: writer)
        }
        
        public static let kind: Kind = .send
    }
    
    public struct Receive : BlockProtocol {
        public var previous: Block.Hash
        public var source: Block.Hash
        public var signature: Signature?
        public var work: Work?
        
        public init(previous: Block.Hash,
                    source: Block.Hash,
                    signature: Signature? = nil,
                    work: Work? = nil)
        {
            self.previous = previous
            self.source = source
            self.signature = signature
            self.work = work
        }
        
        public init(from reader: DataReader) throws {
            previous = try reader.read(Block.Hash.self)
            source = try reader.read(Block.Hash.self)
            try self.readSuffix(from: reader)
        }
        
        public var description: String {
            let fields = [
                "hash=\(hash)",
                "previous=\(previous)",
                "source=\(source)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Receive(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: previous.asData())
            blake.update(data: source.asData())
        }
        
        public func write(to writer: DataWriter) {
            writer.write(previous)
            writer.write(source)
            writeSuffix(to: writer)
        }
        
        public static let kind: Kind = .receive
    }
    
    public struct Open : BlockProtocol {
        public var source: Block.Hash
        public var representative: Account.Address
        public var account: Account.Address
        public var signature: Signature?
        public var work: Work?
        
        public init(source: Block.Hash,
                    representative: Account.Address,
                    account: Account.Address,
                    signature: Signature? = nil,
                    work: Work? = nil)
        {
            self.source = source
            self.representative = representative
            self.account = account
            self.signature = signature
            self.work = work
        }
        
        public init(from reader: DataReader) throws {
            source = try reader.read(Block.Hash.self)
            representative = try reader.read(Account.Address.self)
            account = try reader.read(Account.Address.self)
            try self.readSuffix(from: reader)
        }
        
        public var description: String {
            let fields = [
                "hash=\(hash)",
                "source=\(source)",
                "representative=\(representative)",
                "account=\(account)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Open(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: source.asData())
            blake.update(data: representative.asData())
            blake.update(data: account.asData())
        }
        
        public func write(to writer: DataWriter) {
            writer.write(source)
            writer.write(representative)
            writer.write(account)
            writeSuffix(to: writer)
        }
        
        public static let kind: Kind = .open
    }
    
    public struct Change : BlockProtocol {
        public var previous: Block.Hash
        public var representative: Account.Address
        public var signature: Signature?
        public var work: Work?
        
        public init(previous: Block.Hash,
                    representative: Account.Address,
                    signature: Signature? = nil,
                    work: Work? = nil)
        {
            self.previous = previous
            self.representative = representative
            self.signature = signature
            self.work = work
        }
        
        public init(from reader: DataReader) throws {
            previous = try reader.read(Block.Hash.self)
            representative = try reader.read(Account.Address.self)
            try self.readSuffix(from: reader)
        }
        
        public var description: String {
            let fields = [
                "hash=\(hash)",
                "previous=\(previous)",
                "representative=\(representative)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Change(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: previous.asData())
            blake.update(data: representative.asData())
        }
        
        public func write(to writer: DataWriter) {
            writer.write(previous)
            writer.write(representative)
            writeSuffix(to: writer)
        }
        
        public static let kind: Kind = .change
    }
    
    case send(Send)
    case receive(Receive)
    case open(Open)
    case change(Change)
}

extension Block {    
    public var kind: Block.Kind {
        switch self {
        case .send: return .send
        case .receive: return .receive
        case .open: return .open
        case .change: return .change
        }
    }
    
    public var hash: Block.Hash {
        switch self {
        case .send(let b): return b.hash
        case .receive(let b): return b.hash
        case .open(let b): return b.hash
        case .change(let b): return b.hash
        }
    }
    
    public var work: Work? {
        switch self {
        case .send(let b): return b.work
        case .receive(let b): return b.work
        case .open(let b): return b.work
        case .change(let b): return b.work
        }
    }
}

extension Block : CustomStringConvertible {
    public var description: String {
        switch self {
        case .send(let b): return b.description
        case .receive(let b): return b.description
        case .open(let b): return b.description
        case .change(let b): return b.description
        }
    }
}

extension Block : DataWritable {
    public func write(to writer: DataWriter) {
        switch self {
        case .send(let b): writer.write(b)
        case .receive(let b): writer.write(b)
        case .open(let b): writer.write(b)
        case .change(let b): writer.write(b)
        }
    }
}

extension Block {
    public init(from reader: DataReader, kind: Block.Kind) throws {
        switch kind {
        case .invalid, .notABlock:
            throw GenericError(message: "invalid block kind: \(kind)")
        case .send: self = .send(try .init(from: reader))
        case .receive: self = .receive(try .init(from: reader))
        case .open: self = .open(try .init(from: reader))
        case .change: self = .change(try .init(from: reader))
        }
    }
}

