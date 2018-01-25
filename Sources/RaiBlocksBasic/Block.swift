import Foundation

public enum Block {
    public struct Hash : DataWritable, DataReadable {
        public init(data: Data) {
            precondition(data.count == Hash.size)
            
            self._data = data
        }

        public init(from reader: DataReader) throws {
            let data = try reader.read(Data.self, size: Hash.size)
            self.init(data: data)
        }
        
        public func write(to writer: DataWriter) {
            writer.write(data: _data)
        }
        
        public func asData() -> Data {
            return _data
        }
        
        public static let size: Int = 32
        
        public static let zero: Hash = .init(data: Data.init(count: size))
        
        private let _data: Data
    }
    
    public enum Kind : UInt8 {
        case invalid = 0
        case notABlock
        case send
        case receive
        case open
        case change
    }
    
    public class Send : BlockProtocol {
        public let previous: Block.Hash
        public let destination: Account.Address
        public let balance: Amount
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
        
        public var description: String {
            let fields = [
                "previous=\(previous)",
                "destination=\(destination)",
                "balance=\(balance)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Block.Send(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: previous.asData())
            blake.update(data: destination.asData())
            blake.update(data: balance.asData())
        }
    }
    
    public class Receive : BlockProtocol {
        public let previous: Block.Hash
        public let source: Block.Hash
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
        
        public var description: String {
            let fields = [
                "previous=\(previous)",
                "source=\(source)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Block.Receive(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: previous.asData())
            blake.update(data: source.asData())
        }
    }
    
    public class Open : BlockProtocol {
        public let source: Block.Hash
        public let representative: Account.Address
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
        
        public var description: String {
            let fields = [
                "source=\(source)",
                "representative=\(representative)",
                "account=\(account)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Block.Open(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: source.asData())
            blake.update(data: representative.asData())
            blake.update(data: account.asData())
        }
    }
    
    public class Change : BlockProtocol {
        public let previous: Block.Hash
        public let representative: Account.Address
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
        
        public var description: String {
            let fields = [
                "previous=\(previous)",
                "representative=\(representative)",
                "signature=\(signature?.description ?? "")",
                "work=\(work?.description ?? "")"]
            return "Block.Change(\(fields.joined(separator: ", ")))"
        }
        
        public func hash(blake: Blake2B) {
            blake.update(data: previous.asData())
            blake.update(data: representative.asData())
        }
    }
}

