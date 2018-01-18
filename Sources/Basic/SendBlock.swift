public struct SendBlock {
    public let previous: Block.Hash
    public let destination: Account.Address
    public let balance: Amount
    public let work: Work
    public let signature: Signature
    
    public init(previous: Block.Hash,
                destination: Account.Address,
                balance: Amount,
                work: Work,
                signature: Signature)
    {
        self.previous = previous
        self.destination = destination
        self.balance = balance
        self.work = work
        self.signature = signature
    }
}

extension SendBlock : CustomStringConvertible {
    public var description: String {
        let fields = [
            "previous=\(previous)",
            "destination=\(destination)",
            "balance=\(balance)",
            "work=\(work)"]
        return "SendBlock(\(fields.joined(separator: ", ")))"
    }
}

import Foundation

extension SendBlock {
    public var hash: Block.Hash {
        let blake = Blake2B.init(outputSize: 32)
        blake.update(data: previous.asData())
        blake.update(data: destination.asData())
        blake.update(data: balance.asData())
        return Block.Hash.init(data: blake.finalize())
    }
}
