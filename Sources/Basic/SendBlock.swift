public struct SendBlock {
    public let previous: Block.Hash
    public let destination: Account.Address
    public let balance: Amount
    public var signature: Signature
    public var work: Work

    public init(previous: Block.Hash,
                destination: Account.Address,
                balance: Amount,
                signature: Signature = .zero,
                work: Work = .init(0))
    {
        self.previous = previous
        self.destination = destination
        self.balance = balance
        self.signature = signature
        self.work = work
    }
}

extension SendBlock : CustomStringConvertible {
    public var description: String {
        let fields = [
            "previous=\(previous)",
            "destination=\(destination)",
            "balance=\(balance)",
            "signature=\(signature)",
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

extension SendBlock {
    public mutating func sign(secretKey: SecretKey,
                              address: Account.Address)
    {
        let message = hash.asData()
        self.signature = secretKey.sign(message: message, address: address)
    }
    
    public func verifySignature(address: Account.Address) -> Bool {
        let message = hash.asData()
        return address.verifySignature(message: message, signature: signature)
    }
}

