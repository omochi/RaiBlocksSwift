import Foundation
import SQLite

public class Storage {
    public init(dataDir: FilePath) throws {
        self.dataDir = dataDir
        self.ledgerDBPath = dataDir + "ledger.db"
        self.walletDBPath = dataDir + "wallet.db"

        self.ledgerDB = try SQLite.Connection(ledgerDBPath.description)
        self.walletDB = try SQLite.Connection(walletDBPath.description)
        
        try migrateLedgerDB()
        try migrateWalletDB()
    }
    
    public let dataDir: FilePath
    
    public let ledgerDBPath: FilePath
    public let walletDBPath: FilePath
    
    public func migrateLedgerDB() throws {
        let db = ledgerDB
        let version = try getVersion(db: db)
        print("version = \(version)")
    }
    
    public func migrateWalletDB() throws {
        
    }
    

    private func getVersion(db: SQLite.Connection) throws -> Int {
        try createInfoTableIfNeed(db: db)
        
        let info = SQLite.Table("info")
        let version = SQLite.Expression<Int>("version")
        let row = try db.pluck(info.select(version))!
        return try row.get(version)
    }
    
    private func createInfoTableIfNeed(db: SQLite.Connection) throws {
        let master = SQLite.Table("sqlite_master")
        let name = SQLite.Expression<String>("name")
        let type = SQLite.Expression<String>("type")
        let query = master.select(name)
            .filter(type == "table" && name == "info")
        if try db.pluck(query) == nil {
            let info = SQLite.Table("info")
            let version = SQLite.Expression<Int>("version")
            
            try db.transaction {
                try db.run(info.create { t in
                    t.column(version)
                })
                try db.run(info.insert(version <- 0))
            }
        }
    }
    
    private let ledgerDB: SQLite.Connection
    private let walletDB: SQLite.Connection
}
