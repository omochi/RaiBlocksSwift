import Foundation

public protocol BlockProtocol : class,
    CustomStringConvertible, DataWritable, DataReadable
{
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
    
    public func sign(secretKey: SecretKey,
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
    
    public func writeSuffix(to writer: DataWriter) {
        writer.write(signature ?? .zero)
        writer.write(work ?? .zero)
    }
    
    public func readSuffix(from reader: DataReader) throws {
        let signature = try reader.read(Signature.self)
        self.signature = signature != .zero ? signature : nil
        let work = try reader.read(Work.self)
        self.work = work != .zero ? work : nil
    }
}
