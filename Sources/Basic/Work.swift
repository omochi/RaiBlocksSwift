import Foundation
import CRandom

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

extension Work {
    public func asData() -> Data {
        var data = Data.init(count: 8)
        data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt64>) in
            p.pointee = self.value
        }
        return data
    }
}

extension Work {
    public static func generateRandom() -> Work {
        var data = Data.init(count: 8)
        data.withUnsafeMutableBytes { p in
            crandom_buf(p, data.count)
        }
        let value = data.withUnsafeBytes { (p: UnsafePointer<UInt64>) in
            p.pointee
        }
        return Work(value)
    }
}
