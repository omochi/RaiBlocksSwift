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
            
    private let _value: UInt64
}

extension Work : CustomStringConvertible {
    public var description: String {
        return value.description
    }
}

extension Work : DataConvertible {
    public func asData() -> Data {
        return DataWriter.write(value, byteOrder: .little)
    }
}

extension Work : DataWritable {
    public func write(to writer: DataWriter) {
        writer.write(asData())
    }
}

extension Work : DataReadable {
    public init(data: Data) {
        precondition(data.count == 8)
        self.init(try! DataReader.read(UInt64.self, from: data, byteOrder: .little))
    }
    
    public init(from reader: DataReader) throws {
        let value = try reader.read(UInt64.self, from: .little)
        self.init(value)
    }
}

extension Work : Equatable {}

public func ==(a: Work, b: Work) -> Bool {
    return a.value == b.value
}

extension Work : Comparable {}

public func <(a: Work, b: Work) -> Bool {
    return a.value < b.value
}

extension Work {
    public func score(for hash: Block.Hash) -> UInt64 {
        return score(for: hash.asData())
    }
    
    public func score(for address: Account.Address) -> UInt64 {
        return score(for: address.asData())
    }
    
    public func score(for data: Data) -> UInt64 {
        let blake = Blake2B.init(outputSize: 8)
        blake.update(data: self.asData())
        blake.update(data: data)
        let data = blake.finalize()
        return try! DataReader.read(UInt64.self, from: data, byteOrder: .little)
    }
}

extension Work {
    public static func generateRandom() -> Work {
        return Work(Random.getUInt64())
    }
}

public func ==(a: Work?, b: Work?) -> Bool {
    switch (a, b) {
    case (.some(let aw), .some(let bw)): return aw == bw
    case (.some, .none): return false
    case (.none, .some): return false
    case (.none, .none): return true
    }
}

public func <(a: Work?, b: Work?) -> Bool {
    switch (a, b) {
    case (.some(let aw), .some(let bw)): return aw < bw
    case (.some, .none): return false
    case (.none, .some): return true
    case (.none, .none): return false
    }
}

public func <=(a: Work?, b: Work?) -> Bool {
    return !(b < a)
}
