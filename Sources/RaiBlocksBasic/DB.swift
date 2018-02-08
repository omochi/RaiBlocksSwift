import Foundation
import SQLite

extension SQLite.Blob {
    public init(data: Data) {
        self.init(bytes: Array<UInt8>(data))
    }
    
    public func asData() -> Data {
        return Data(bytes)
    }
    
    public func asBlockHash() -> Block.Hash {
        return Block.Hash(data: asData())
    }
    
    public func asAmount() -> Amount {
        return Amount(data: asData())
    }
    
    public func asAccountAddress() -> Account.Address {
        return Account.Address(data: asData())
    }
    
    public func asSignature() -> Signature {
        return Signature(data: asData())
    }
    
    public func asWork() -> Work {
        return Work(data: asData())
    }
}

public enum DB {
    public class InfoTable {
        public struct Row {
            public var version: Int
            public var network: String
            
            public init(version: Int,
                        network: String)
            {
                self.version = version
                self.network = network
            }
        }
        
        public init() {
            self.table = .init("info")
            self.version = .init("version")
            self.network = .init("network")
        }
        
        public let table: SQLite.Table
        public let version: SQLite.Expression<Int>
        public let network: SQLite.Expression<String>
    }
    
    public class BlocksTable {
        public struct Row {
            public var hash: Block.Hash
            public var kind: Block.Kind
            public var previous: Block.Hash?
            public var source: Block.Hash?
            public var destination: Account.Address?
            public var balance: Amount?
            public var representative: Account.Address?
            public var account: Account.Address?
            public var signature: Signature?
            public var work: Work?
            public var pending: Bool
            
            public init(hash: Block.Hash,
                        kind: Block.Kind,
                        previous: Block.Hash?,
                        source: Block.Hash?,
                        destination: Account.Address?,
                        balance: Amount?,
                        representative: Account.Address?,
                        account: Account.Address?,
                        signature: Signature?,
                        work: Work?,
                        pending: Bool)
            {
                self.hash = hash
                self.kind = kind
                self.previous = previous
                self.source = source
                self.destination = destination
                self.balance = balance
                self.representative = representative
                self.account = account
                self.signature = signature
                self.work = work
                self.pending = pending
            }
        }
        
        public init() {
            self.table = .init("blocks")
            self.hash = .init("hash")
            self.kind = .init("kind")
            self.previous = .init("previous")
            self.source = .init("source")
            self.destination = .init("destination")
            self.balance = .init("balance")
            self.representative = .init("representative")
            self.account = .init("account")
            self.signature = .init("signature")
            self.work = .init("work")
            self.pending = .init("pending")
        }
        
        public let table: SQLite.Table
        public let hash: SQLite.Expression<SQLite.Blob>
        public let kind: SQLite.Expression<Int>
        public let previous: SQLite.Expression<SQLite.Blob?>
        public let source: SQLite.Expression<SQLite.Blob?>
        public let destination: SQLite.Expression<SQLite.Blob?>
        public let balance: SQLite.Expression<SQLite.Blob?>
        public let representative: SQLite.Expression<SQLite.Blob?>
        public let account: SQLite.Expression<SQLite.Blob?>
        public let signature: SQLite.Expression<SQLite.Blob?>
        public let work: SQLite.Expression<SQLite.Blob?>
        public let pending: SQLite.Expression<Bool>
    }
    
    public class AccountsTable {
        public init() {
            self.table = .init("accounts")
            self.address = .init("address")
            self.headBlock = .init("head_block")
            self.amount = .init("amount")
            self.representativeBlock = .init("representative_block")
            self.blockCount = .init("block_count")
        }
        
        public let table: SQLite.Table
        public let address: SQLite.Expression<Blob>
        public let headBlock: SQLite.Expression<Blob>
        public let amount: SQLite.Expression<Blob>
        public let representativeBlock: SQLite.Expression<Blob>
        public let blockCount: SQLite.Expression<Int>
    }
    
    public static let info: InfoTable = .init()
    public static let blocks: BlocksTable = .init()
    public static let accounts: AccountsTable = .init()
    
    public static func migrateLedgerDB(connection: SQLite.Connection,
                                       network: Network) throws {
        if let row = try info.getRow(connection: connection) {
            guard row.network == network.name else {
                throw GenericError(message: "invalid storage network: expected=\(network.name), actual=\(row.network)")
            }
        } else {
            try connection.run(info.table.insert(info.version <- 1,
                                                 info.network <- network.name))
            try blocks.create(connection: connection)
            try accounts.create(connection: connection)
        }
    }
}
