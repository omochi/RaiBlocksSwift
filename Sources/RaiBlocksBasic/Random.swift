import Foundation
import RaiBlocksCRandom

public enum Random {
    public static func getUInt() -> UInt {
        return getValue(of: UInt.self)
    }
    
    public static func getUInt32() -> UInt32 {
        return getValue(of: UInt32.self)
    }
    
    public static func getUInt64() -> UInt64 {
        return getValue(of: UInt64.self)
    }
    
    public static func getValue<T: BinaryInteger>(of type: T.Type) -> T {
        var data = Data.init(count: MemoryLayout<T>.size)
        data.withUnsafeMutableBytes { p in
            crandom_buf(p, data.count)
        }
        return data.withUnsafeBytes { (p: UnsafePointer<T>) in
            p.pointee
        }
    }
}

extension Collection where Index == Int, IndexDistance == Int {
    public func getRandom() -> Element? {
        return getRandomIndex().map { self[$0] }
    }
    
    public func getRandomIndex() -> Int?
    {
        guard count > 0 else {
            return nil
        }
        let dice = Int(Random.getUInt() % UInt(count))
        return self.index(startIndex, offsetBy: dice)
    }
}
