import Foundation
import SQLite

public class Ledger {
    public init(environment: Environment) throws {
        self.environment = environment
        self.dbPath = environment.dataDir + "ledger.db"
        self.dbConnection = try SQLite.Connection(dbPath.description)
        try DB.migrateLedgerDB(connection: dbConnection)
    }
    
    private let environment: Environment
    private let dbPath: FilePath
    private let dbConnection: SQLite.Connection
}
