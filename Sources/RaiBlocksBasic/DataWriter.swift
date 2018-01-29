import Foundation
import BigInt

public class DataWriter {
    public init() {
        self.data = Data.init()
    }
    
    public func write(_ pointer: UnsafePointer<UInt8>, size: Int) {
        data.append(pointer, count: size)
    }
    
    public func write(data: Data) {
        data.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            write(p, size: data.count)
        }
    }
    
    public func write(_ value: UInt8) {
        var value = value
        let size = 1
        UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            write(p, size: size)
        }
    }
    
    public func write(_ value: UInt16) {
        var value = NSSwapHostShortToBig(value)
        let size = 2
        UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            write(p, size: size)
        }
    }
    
    public func write(_ value: UInt32) {
        var value = NSSwapHostIntToBig(value)
        let size = 4
        UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            write(p, size: size)
        }
    }
    
    public func write(_ value: UInt64) {
        var value = NSSwapHostLongLongToBig(value)
        let size = 8
        UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            write(p, size: size)
        }
    }
    
    public func write<X: DataWritable>(_ value: X) {
        value.write(to: self)
    }
    
    public private(set) var data: Data
}

public protocol DataWritable {
    func write(to writer: DataWriter)
}

extension DataWritable {
    public func writeToData() -> Data {
        let writer = DataWriter()
        self.write(to: writer)
        return writer.data
    }
}


