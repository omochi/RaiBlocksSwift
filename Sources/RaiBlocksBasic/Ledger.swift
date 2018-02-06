import Foundation
import SQLite

public class Ledger {
    public init(queue: DispatchQueue,
                logger: Logger,
                storage: Storage)
    {
        self.queue = queue
        self.logger = Logger(config: logger.config, tag: "Ledger")
        self.storage = storage
        self.recoveryInterval = 10
        self.blockQueueSize = 1000
        self.blockQueue = []
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
        queue.async {
            if self.blockQueue.count == self.blockQueueSize {
                self.logger.warn("block queue is full. discard: \(block.hash)")
                return
            }
            
            self.blockQueue.append(block)
            self.run()
        }
    }
    
    private enum BlockResult {
        case ok
        case alreadyHave
        case needPrevious
    }
    
    private func run() {
        while let block = blockQueue.first {
            blockQueue.remove(at: 0)
            
            do {
                try storage.ledgerDBTransaction { connection in
                    try process(block: block, connection: connection)
                }
            } catch let error {
                logger.error("\(error)")
                
                blockQueue.insert(block, at: 0)
                
                recoveryTimer = makeTimer(delay: recoveryInterval, queue: queue) {
                    self.run()
                }

                break
            }
        }
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
    private let storage: Storage
    private let recoveryInterval: TimeInterval
    private let blockQueueSize: Int
    private var blockQueue: [Block]
    private var recoveryTimer: DispatchSourceTimer?
}
