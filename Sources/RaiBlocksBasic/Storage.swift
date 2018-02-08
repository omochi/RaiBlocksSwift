import Foundation
import SQLite

public class Storage {
    public init(fileSystem: FileSystem,
                network: Network) throws
    {
        self.fileSystem = fileSystem
        self.network = network
        
        self.ledgerDBPath = fileSystem.dataDir + "ledger.db"
        self.walletDBPath = fileSystem.dataDir + "wallet.db"

        self.ledgerDBConnection = try SQLite.Connection(ledgerDBPath.description)
        self.walletDBConnection = try SQLite.Connection(walletDBPath.description)
        
        try self.ledgerDBTransaction { connection in
            try DB.migrateLedgerDB(connection: connection, network: network)
        }
    }
    
    public let fileSystem: FileSystem
    public let network: Network
    
    public func ledgerDBTransaction<R>(_ body: (SQLite.Connection) throws -> R) throws -> R {
        var ret: R?
        let connection = ledgerDBConnection
        try connection.transaction(Connection.TransactionMode.exclusive) {            
            ret = try body(connection)
        }
        return ret!
    }
    
    private let ledgerDBPath: FilePath
    private let walletDBPath: FilePath

    private let ledgerDBConnection: SQLite.Connection
    private let walletDBConnection: SQLite.Connection
}
