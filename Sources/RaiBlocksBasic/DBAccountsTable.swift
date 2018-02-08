import SQLite

extension DB.AccountsTable {
    public func create(connection: SQLite.Connection) throws {
        try connection.run(table.create { t in
            t.column(address, unique: true)
            t.column(headBlock, unique: true)
            t.column(amount)
            t.column(representativeBlock)
            t.column(blockCount)
        })
    }
    
    public func put(account: Account,
                    connection: SQLite.Connection) throws {
        try connection.run(table.filter(address == account.address.asSQLite()).delete())
        try connection.run(table.insert(address <- account.address.asSQLite(),
                                        headBlock <- account.headBlock.asSQLite(),
                                        amount <- account.amount.asSQLite(),
                                        representativeBlock <- account.representativeBlock.asSQLite(),
                                        blockCount <- account.blockCount))
    }
    
    public func getAccount(address: Account.Address,
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
