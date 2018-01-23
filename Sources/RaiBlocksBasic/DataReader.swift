import Foundation

public class DataReader {
    public init(data: Data) {
        self.data = data
        self.position = 0
    }
    
    public func read(_ pointer: UnsafeMutablePointer<UInt8>, size: Int) throws {
        guard position + size <= data.count else {
            throw GenericError.init(message: "read(\(size)): not enough data: position=\(position), data=\(data.count)")
        }
        data.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            pointer.assign(from: p + position, count: size)
        }
        position += size
    }
    
    public func read(_ type: Data.Type, size: Int) throws -> Data {
        var chunk = Data.init(count: size)
        try chunk.withUnsafeMutableBytes { p in
            try read(p, size: size)
        }
        return chunk
    }
    
    public func read(_ type: UInt8.Type) throws -> UInt8 {
        var value = UInt8()
        try read(&value, size: 1)
        return value
    }
    
    public func read(_ type: UInt16.Type) throws -> UInt16 {
        let size = 2
        var value = UInt16()
        try UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            try read(p, size: size)
        }
        return NSSwapBigShortToHost(value)
    }
    
    public func read(_ type: UInt32.Type) throws -> UInt32 {
        let size = 4
        var value = UInt32()
        try UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            try read(p, size: size)
        }
        return NSSwapBigIntToHost(value)
    }
    
    public func read(_ type: UInt64.Type) throws -> UInt64 {
        let size = 8
        var value = UInt64()
        try UnsafeMutablePointer(&value).withMemoryRebound(to: UInt8.self, capacity: size) { p in
            try read(p, size: size)
        }
        return NSSwapBigLongLongToHost(value)
    }
    
    public let data: Data
    public var position: Int
}

public protocol DataReadable {
    init(from reader: DataReader) throws
}

extension DataReadable {
    public init(from data: Data) throws {
        let reader = DataReader.init(data: data)
        try self.init(from: reader)
    }
}