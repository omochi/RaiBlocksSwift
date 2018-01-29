import Foundation
import SQLite

public class Storage {
    public init(dataDir: FilePath) throws {
        self.dataDir = dataDir
        self.ledgerDBPath = dataDir + "ledger.db"
        self.walletDBPath = dataDir + "wallet.db"

        self.ledgerDBConnection = try SQLite.Connection(ledgerDBPath.description)
        try DB.migrateLedgerDB(connection: ledgerDBConnection)
        
        self.walletDBConnection = try SQLite.Connection(walletDBPath.description)
    }
    
    public let dataDir: FilePath
    
    public let ledgerDBPath: FilePath
    public let walletDBPath: FilePath

    private let ledgerDBConnection: SQLite.Connection
    private let walletDBConnection: SQLite.Connection
}
