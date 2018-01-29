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
        public init() {
            self.table = .init("info")
            self.version = .init("version")
        }
        
        public let table: SQLite.Table
        public let version: SQLite.Expression<Int>
        
        public func createIfNotExists(connection: SQLite.Connection) throws {
            try connection.run(table.create(ifNotExists: true) { t in
                t.column(version)
            })
        }
        
        public func getVersion(connection: SQLite.Connection) throws -> Int? {
            try DB.info.createIfNotExists(connection: connection)
            let row = try connection.pluck(DB.info.table.select(DB.info.version))
            return row?[DB.info.version]
        }
    }
    
    public class BlocksTable {
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
        
        public func create(connection: SQLite.Connection) throws {
            try connection.run(table.create() { t in
                t.column(hash, unique: true)
                t.column(kind)
                t.column(previous)
                t.column(source)
                t.column(destination)
                t.column(balance)
                t.column(representative)
                t.column(account)
                t.column(signature)
                t.column(work)
            })
        }
        
        public func write(block: Block.Send,
                          connection: SQLite.Connection) throws {
            let blockHash = block.hash
            try connection.run(table.filter(hash == blockHash.asSQLite()).delete())
            try connection.run(table.insert(hash <- blockHash.asSQLite(),
                                            kind <- Int(type(of: block).kind.rawValue),
                                            previous <- block.previous.asSQLite(),
                                            destination <- block.destination.asSQLite(),
                                            balance <- block.balance.asSQLite(),
                                            signature <- block.signature?.asSQLite(),
                                            work <- block.work?.asSQLite()
                                            ))
        }
        
        public func write(block: Block.Receive,
                          connection: SQLite.Connection) throws {
            let blockHash = block.hash
            try connection.run(table.filter(hash == blockHash.asSQLite()).delete())
            try connection.run(table.insert(hash <- blockHash.asSQLite(),
                                            kind <- Int(type(of: block).kind.rawValue),
                                            previous <- block.previous.asSQLite(),
                                            source <- block.source.asSQLite(),
                                            signature <- block.signature?.asSQLite(),
                                            work <- block.work?.asSQLite()
            ))
        }
        
        public func write(block: Block.Open,
                          connection: SQLite.Connection) throws {
            let blockHash = block.hash
            try connection.run(table.filter(hash == blockHash.asSQLite()).delete())
            try connection.run(table.insert(hash <- blockHash.asSQLite(),
                                            kind <- Int(type(of: block).kind.rawValue),
                                            source <- block.source.asSQLite(),
                                            representative <- block.representative.asSQLite(),
                                            account <- block.account.asSQLite(),
                                            signature <- block.signature?.asSQLite(),
                                            work <- block.work?.asSQLite()
            ))
        }
        
        public func write(block: Block.Change,
                          connection: SQLite.Connection) throws {
            let blockHash = block.hash
            try connection.run(table.filter(hash == blockHash.asSQLite()).delete())
            try connection.run(table.insert(hash <- blockHash.asSQLite(),
                                            kind <- Int(type(of: block).kind.rawValue),
                                            previous <- block.previous.asSQLite(),
                                            representative <- block.representative.asSQLite(),
                                            signature <- block.signature?.asSQLite(),
                                            work <- block.work?.asSQLite()
            ))
        }
        
        public func write(block: Block,
                          connection: SQLite.Connection) throws {
            switch block {
            case .send(let b):
                try write(block: b, connection: connection)
            case .receive(let b):
                try write(block: b, connection: connection)
            case .open(let b):
                try write(block: b, connection: connection)
            case .change(let b):
                try write(block: b, connection: connection)
            }
        }
        
        public func read(hash: Block.Hash,
                         connection: SQLite.Connection) throws -> Block?
        {
            guard let row = try connection.pluck(table.select(*)
                .filter(self.hash == hash.asSQLite())) else
            {
                return nil
            }
            let kind = Block.Kind(rawValue: UInt8(try row.get(self.kind)))!
            switch kind {
            case .send:
                return .send(Block.Send(previous: row[previous]!.asBlockHash(),
                                        destination: row[destination]!.asAccountAddress(),
                                        balance: row[balance]!.asAmount(),
                                        signature: row[signature]?.asSignature(),
                                        work: row[work]?.asWork()))
            case .receive:
                return .receive(Block.Receive(previous: row[previous]!.asBlockHash(),
                                              source: row[source]!.asBlockHash(),
                                              signature: row[signature]?.asSignature(),
                                              work: row[work]?.asWork()))
            case .open:
                return .open(Block.Open(source: row[source]!.asBlockHash(),
                                        representative: row[representative]!.asAccountAddress(),
                                        account: row[account]!.asAccountAddress(),
                                        signature: row[signature]?.asSignature(),
                                        work: row[work]?.asWork()))
            case .change:
                return .change(Block.Change(previous: row[previous]!.asBlockHash(),
                                            representative: row[representative]!.asAccountAddress(),
                                            signature: row[signature]?.asSignature(),
                                            work: row[work]?.asWork()))
            default:
                fatalError("invalid kind: \(kind)")
            }
        }
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
        
        public func create(connection: SQLite.Connection) throws {
            try connection.run(table.create { t in
                t.column(address, unique: true)
                t.column(headBlock, unique: true)
                t.column(amount)
                t.column(representativeBlock)
                t.column(blockCount)
            })
        }
        
        public func write(account: Account,
                          connection: SQLite.Connection) throws {
            try connection.run(table.filter(address == account.address.asSQLite()).delete())
            try connection.run(table.insert(address <- account.address.asSQLite(),
                                            headBlock <- account.headBlock.asSQLite(),
                                            amount <- account.amount.asSQLite(),
                                            representativeBlock <- account.representativeBlock.asSQLite(),
                                            blockCount <- account.blockCount))
        }
        
        public func read(address: Account.Address,
                         connection: SQLite.Connection) throws -> Account? {
            guard let row = try connection.pluck(table.select(*)
                .filter(self.address == address.asSQLite())) else {
                return nil
            }
            return Account(address: row[self.address].asAccountAddress(),
                           headBlock: row[headBlock].asBlockHash(),
                           amount: row[amount].asAmount(),
                           representativeBlock: row[representativeBlock].asBlockHash(),
                           blockCount: row[blockCount])
        }
    }
    
    public static let info: InfoTable = .init()
    public static let blocks: BlocksTable = .init()
    public static let accounts: AccountsTable = .init()
    
    public static func migrateLedgerDB(connection: SQLite.Connection) throws {
        try connection.transaction {
            let version = try info.getVersion(connection: connection)
            if version == nil {
                try connection.run(info.table.insert(info.version <- 1))
                try blocks.create(connection: connection)
                try accounts.create(connection: connection)
            }
        }
        
    }
}
