import Foundation
import SQLite

public class Ledger {
    public init(queue: DispatchQueue,
                loggerConfig: Logger.Config,
                network: Network,
                storage: Storage) throws
    {
        precondition(storage.network === network)
        
        self.queue = queue
        self.logger = Logger(config: loggerConfig, tag: "Ledger")
        self.network = network
        self.storage = storage
        self.recoveryInterval = 10
        self.blockQueueSize = 1000
        self.blockQueue = []
        self.running = false
        
        try mayRegisterGenesis()
    }
    
    public func terminate() {
        queue.sync {
            if blockQueue.count > 0 {
                logger.warn("terminate. discard \(blockQueue.count) blocks")
                
                blockQueue.removeAll()
            }
            
            recoveryTimer?.cancel()
            recoveryTimer = nil
        }
    }
    
    public func push(block: Block) {
        queue.sync {
            if blockQueue.count == blockQueueSize {
                logger.warn("block queue is full. discard: \(block.hash)")
                return
            }
            
            blockQueue.append(block)
            scheduleRun()
        }
    }
    
    private func mayRegisterGenesis() throws {
        try storage.ledgerDBTransaction { connection in
            let genesis = network.genesis
            
            if try DB.blocks.getBlock(hash: genesis.block.hash, connection: connection) == nil {
                try DB.blocks.put(block: .open(genesis.block), connection: connection)
            }
            
            if try DB.accounts.getAccount(address: genesis.account.address, connection: connection) == nil {
                try DB.accounts.put(account: genesis.account, connection: connection)
            }
        }
    }
    
    private enum BlockResult {
        case ok
        case alreadyHave
        case needPrevious
    }

    private func scheduleRun() {
        queue.async {
            if self.running {
                return
            }
            
            self.running = true
            self.run()
        }
    }
    
    private func run() {
        assert(running)
        
        recoveryTimer?.cancel()
        recoveryTimer = nil
        
        if let block = blockQueue.first {
            blockQueue.remove(at: 0)
            
            do {
                try storage.ledgerDBTransaction { connection in
                    try process(block: block, connection: connection)
                }
            } catch let error {
                logger.error("\(error)")
                
                blockQueue.insert(block, at: 0)
                
                recoveryTimer = makeTimer(delay: recoveryInterval, queue: queue) {
                    self.scheduleRun()
                }
                
                running = false
                return
            }
            
            queue.async {
                self.run()
            }
            
            return
        }
        
        running = false
    }
    
    private func process(block: Block,
                         connection: SQLite.Connection) throws {
        let result: BlockResult
        switch block {
        case .send(let block):
            result = try process(sendBlock: block, connection: connection)
        case .receive(let block):
            break
        case .open(let block):
            break
        case .change(let block):
            break
        }
    }
    
    private func process(sendBlock block: Block.Send,
                         connection: SQLite.Connection) throws -> BlockResult
    {
        if let _ = try DB.blocks.getBlock(hash: block.hash, connection: connection) {
            return .alreadyHave
        }
        
        guard let previousBlock = try DB.blocks.getBlock(hash: block.previous, connection: connection) else {
            return .needPrevious
        }
        
        // TODO
        fatalError("TODO")
    }
    
    private let queue: DispatchQueue
    private let logger: Logger
    private let network: Network
    private let storage: Storage
    private let recoveryInterval: TimeInterval
    private let blockQueueSize: Int
    private var blockQueue: [Block]
    private var recoveryTimer: DispatchSourceTimer?
    private var running: Bool
}
