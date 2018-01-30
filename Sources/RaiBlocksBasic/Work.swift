import Foundation
import RaiBlocksRandom

public struct Work {
    public init(_ value: UInt64) {
        self._value = value
    }

    public var value: UInt64 {
        return _value
    }
    
    public static let zero: Work = .init(0)
    
    public static let scoreThreshold: UInt64 = 0xFFFFFFC000000000
        
    private let _value: UInt64
}

extension Work : CustomStringConvertible {
    public var description: String {
        return value.description
    }
}

extension Work : DataWritable {
    public init(data: Data) {
        precondition(data.count == 8)
        let value = data.withUnsafeBytes { (p: UnsafePointer<UInt64>) in
            p.pointee
        }
        self.init(value.convert(from: .little))
    }
    
    public func write(to writer: DataWriter) {
        writer.write(self.value, byteOrder: .little)
    }
}

extension Work {
    public func score(for hash: Block.Hash) -> UInt64 {
        let blake = Blake2B.init(outputSize: 8)
        blake.update(data: self.asData())
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
