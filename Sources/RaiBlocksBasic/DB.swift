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
            
            public init(from block: Block,
                        pending: Bool)
            {
                switch block {
                case .send(let b):
                    self.init(hash: b.hash,
                              kind: type(of: b).kind,
                              previous: b.previous,
                              source: nil,
                              destination: b.destination,
                              balance: b.balance,
                              representative: nil,
                              account: nil,
                              signature: b.signature,
                              work: b.work,
                              pending: pending)
                case .receive(let b):
                    self.init(hash: b.hash,
                              kind: type(of: b).kind,
                              previous: b.previous,
                              source: b.source,
                              destination: nil,
                              balance: nil,
                              representative: nil,
                              account: nil,
                              signature: b.signature,
                              work: b.work,
                              pending: pending)
                case .open(let b):
                    self.init(hash: b.hash,
                              kind: type(of: b).kind,
                              previous: nil,
                              source: b.source,
                              destination: nil,
                              balance: nil,
                              representative: b.representative,
                              account: b.account,
                              signature: b.signature,
                              work: b.work,
                              pending: pending)
                case .change(let b):
                    self.init(hash: b.hash,
                              kind: type(of: b).kind,
                              previous: b.previous,
                              source: nil,
                              destination: nil,
                              balance: nil,
                              representative: b.representative,
                              account: nil,
                              signature: b.signature,
                              work: b.work,
                              pending: pending)
                }
            }
            
            public func toBlock() -> Block {
                switch kind {
                case .send:
                    return .send(Block.Send(previous: previous!,
                                            destination: destination!,
                                            balance: balance!,
                                            signature: signature,
                                            work: work))
                case .receive:
                    return .receive(Block.Receive(previous: previous!,
                                                  source: source!,
                                                  signature: signature,
                                                  work: work))
                case .open:
                    return .open(Block.Open(source: source!,
                                            representative: representative!,
                                            account: account!,
                                            signature: signature,
                                            work: work))
                case .change:
                    return .change(Block.Change(previous: previous!,
                                                representative: representative!,
                                                signature: signature,
                                                work: work))
                default:
                    fatalError("invalid block kind: \(kind)")
                }
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
                t.column(pending)
            })
        }
        
        public func put(row: Row,
                        connection: SQLite.Connection) throws {
            try connection.run(table.filter(hash == row.hash.asSQLite()).delete())
            try connection.run(table.insert(hash <- row.hash.asSQLite(),
                                            kind <- Int(row.kind.rawValue),
                                            previous <- row.previous?.asSQLite(),
                                            source <- row.source?.asSQLite(),
                                            destination <- row.destination?.asSQLite(),
                                            balance <- row.balance?.asSQLite(),
                                            representative <- row.representative?.asSQLite(),
                                            account <- row.account?.asSQLite(),
                                            signature <- row.signature?.asSQLite(),
                                            work <- row.work?.asSQLite(),
                                            pending <- row.pending))
        }
        
        public func put(block: Block,
                        connection: SQLite.Connection) throws
        {
            let row = Row(from: block, pending: false)
            try put(row: row, connection: connection)
        }
        
        public func getRow(hash: Block.Hash,
                           pending: Bool?,
                           connection: SQLite.Connection) throws -> Row?
        {
            var query = table.select(*).filter(self.hash == hash.asSQLite())
            if let pending = pending {
                query = query.filter(self.pending == pending)
            }
            
            guard let row = try connection.pluck(query) else
            {
                return nil
            }
            return Row(hash: row[self.hash].asBlockHash(),
                       kind: Block.Kind(rawValue: UInt8(row[kind]))!,
                       previous: row[previous]?.asBlockHash(),
                       source: row[source]?.asBlockHash(),
                       destination: row[destination]?.asAccountAddress(),
                       balance: row[balance]?.asAmount(),
                       representative: row[representative]?.asAccountAddress(),
                       account: row[account]?.asAccountAddress(),
                       signature: row[signature]?.asSignature(),
                       work: row[work]?.asWork(),
                       pending: row[self.pending])
        }
        
        public func getBlock(hash: Block.Hash,
                             connection: SQLite.Connection) throws -> Block?
        {
            guard let row = try getRow(hash: hash, pending: false, connection: connection) else {
                return nil
            }
            return row.toBlock()
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
        let version = try info.getVersion(connection: connection)
        if version == nil {
            try connection.run(info.table.insert(info.version <- 1))
            try blocks.create(connection: connection)
            try accounts.create(connection: connection)
        }
    }
}
