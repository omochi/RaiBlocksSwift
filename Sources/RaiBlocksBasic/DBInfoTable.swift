import SQLite

extension DB.InfoTable {
    public func createIfNotExists(connection: SQLite.Connection) throws {
        try connection.run(table.create(ifNotExists: true) { t in
            t.column(version)
            t.column(network)
        })
    }
    
    public func getRow(connection: SQLite.Connection) throws -> Row? {
        try DB.info.createIfNotExists(connection: connection)
        guard let row = try connection.pluck(DB.info.table.select(*)) else {
            return nil
        }
        return Row(version: row[self.version],
                   network: row[self.network])
    }
}
