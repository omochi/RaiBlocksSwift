import Foundation

extension Block.Hash : CustomStringConvertible {
    public var description: String {
        return asData().toHex()
    }
}

extension Block.Hash {
    public init(hexString: String) {
        let data = Data.init(hexString: hexString)
        self.init(data: data)
    }
}

extension Block.Hash : Equatable {}

public func ==(a: Block.Hash, b: Block.Hash) -> Bool {
    return a.asData() == b.asData()
}

extension Block.Hash {
    public func score(of work: Work) -> UInt64 {
        let blake = Blake2B.init(outputSize: 8)
        blake.update(data: work.asData())
        blake.update(data: asData())
        let data = blake.finalize()
        return data.withUnsafeBytes { (p: UnsafePointer<UInt64>) in
            return p.pointee
        }
    }
}
