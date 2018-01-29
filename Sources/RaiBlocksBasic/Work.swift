import Foundation
import RaiBlocksCRandom

public struct Work {
    public init(_ value: UInt64) {
        self._value = value
    }
    
    public var value: UInt64 {
        return _value
    }
    
    public static let scoreThreshold: UInt64 = 0xFFFFFFC000000000
        
    private let _value: UInt64
}

extension Work : CustomStringConvertible {
    public var description: String {
        return value.description
    }
}

extension Work : DataConvertible {
    public init(data: Data) {
        precondition(data.count == 8)
        let value = data.withUnsafeBytes { (p: UnsafePointer<UInt64>) in
            p.pointee
        }
        self.init(NSSwapBigLongLongToHost(value))
    }

    public func asData() -> Data {
        let value = NSSwapHostLongLongToBig(self.value)
        var data = Data.init(count: 8)
        data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt64>) in
            p.pointee = value
        }
        return data
    }
}

extension Work {
    public func score(for hash: Block.Hash) -> UInt64 {
        let blake = Blake2B.init(outputSize: 8)
        blake.update(data: Data(self.asData().reversed()))
        blake.update(data: hash.asData())
        let data = blake.finalize()
        return data.withUnsafeBytes { (p: UnsafePointer<UInt64>) in
            return p.pointee
        }
    }
    
    public func verify(for hash: Block.Hash, threshold: UInt64) -> Bool {
        return score(for: hash) >= threshold
    }
}

extension Work {
    public static func generateRandom() -> Work {
        return Work(Random.getUInt64())
    }
}
