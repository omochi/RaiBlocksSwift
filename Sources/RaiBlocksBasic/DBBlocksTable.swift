import SQLite

extension DB.BlocksTable.Row {
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

extension DB.BlocksTable {
    
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
