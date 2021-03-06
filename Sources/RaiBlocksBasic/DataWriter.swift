import Foundation
import RaiBlocksSocket

public class DataWriter {
    public init() {
        self.data = Data.init()
    }
    
    public func write(_ pointer: UnsafePointer<UInt8>, size: Int) {
        data.append(pointer, count: size)
    }
    
    public func write(_ data: Data) {
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
    
    public func write(_ value: UInt16, byteOrder: ByteOrder) {
        var value = value.convert(to: byteOrder)
        let size = 2
        UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            write(p, size: size)
        }
    }
    
    public func write(_ value: UInt32, byteOrder: ByteOrder) {
        var value = value.convert(to: byteOrder)
        let size = 4
        UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            write(p, size: size)
        }
    }
    
    public func write(_ value: UInt64, byteOrder: ByteOrder) {
        var value = value.convert(to: byteOrder)
        let size = 8
        UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            write(p, size: size)
        }
    }
    
    public func write<X: DataWritable>(_ value: X) {
        value.write(to: self)
    }
    
    public private(set) var data: Data
    
    public static func write(_ value: UInt64, byteOrder: ByteOrder) -> Data {
        let writer = DataWriter()
        writer.write(value, byteOrder: byteOrder)
        return writer.data
    }
}

public protocol DataWritable {
    func write(to writer: DataWriter)    
}



