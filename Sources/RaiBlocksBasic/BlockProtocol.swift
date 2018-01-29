import Foundation

public protocol BlockProtocol : CustomStringConvertible {
    var signature: Signature? { get set }
    var work: Work? { get set }
    
    func hash(blake: Blake2B)
    
    static var kind: Block.Kind { get }
}

extension BlockProtocol {
    public var hash: Block.Hash {
        let blake = Blake2B.init(outputSize: 32)
        self.hash(blake: blake)
        return Block.Hash.init(data: blake.finalize())
    }
    
    public mutating func sign(secretKey: SecretKey,
                              address: Account.Address)
    {
        let message = hash.asData()
        self.signature = secretKey.sign(message: message, address: address)
    }
    
    public func verifySignature(address: Account.Address) -> Bool {
        guard let signature = self.signature else {
            return false
        }
        
        let message = hash.asData()
        return address.verifySignature(message: message, signature: signature)
    }
    
    public var scoreOfWork: UInt64? {
        guard let work = self.work else {
            return nil
        }
        return work.score(for: hash)
    }
}
