import Foundation
import SQLite

public class Storage {
    public init(environment: Environment) throws {
        self.dataDir = environment.dataDir
        self.ledgerDBPath = dataDir + "ledger.db"
        self.walletDBPath = dataDir + "wallet.db"

        self.ledgerDBConnection = try SQLite.Connection(ledgerDBPath.description)
        self.walletDBConnection = try SQLite.Connection(walletDBPath.description)
        
        try self.ledgerDBTransaction { conn in
            try DB.migrateLedgerDB(connection: conn)
        }
    }
    
    public func ledgerDBTransaction<R>(_ body: (SQLite.Connection) throws -> R) throws -> R {
        var ret: R?
        let conn = ledgerDBConnection
        try conn.transaction {
            ret = try body(conn)
        }
        return ret!
    }
    
    private let dataDir: FilePath
    
    private let ledgerDBPath: FilePath
    private let walletDBPath: FilePath

    private let ledgerDBConnection: SQLite.Connection
    private let walletDBConnection: SQLite.Connection
}
