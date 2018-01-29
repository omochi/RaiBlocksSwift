import Foundation

public enum ByteOrder {
    case little
    case big
}

extension UInt16 {
    public func convert(to byteOrder: ByteOrder) -> UInt16 {
        switch byteOrder {
        case .little:
            return NSSwapHostShortToLittle(self)
        case .big:
            return NSSwapHostShortToBig(self)
        }
    }
    
    public func convert(from byteOrder: ByteOrder) -> UInt16 {
        switch byteOrder {
        case .little:
            return NSSwapLittleShortToHost(self)
        case .big:
            return NSSwapBigShortToHost(self)
        }
    }
}

extension UInt32 {
    public func convert(to endian: ByteOrder) -> UInt32 {
        switch endian {
        case .little:
            return NSSwapHostIntToLittle(self)
        case .big:
            return NSSwapHostIntToBig(self)
        }
    }
    
    public func convert(from endian: ByteOrder) -> UInt32 {
        switch endian {
        case .little:
            return NSSwapLittleIntToHost(self)
        case .big:
            return NSSwapBigIntToHost(self)
        }
    }
}

extension UInt64 {
    public func convert(to endian: ByteOrder) -> UInt64 {
        switch endian {
        case .little:
            return NSSwapHostLongLongToLittle(self)
        case .big:
            return NSSwapHostLongLongToBig(self)
        }
    }
    
    public func convert(from endian: ByteOrder) -> UInt64 {
        switch endian {
        case .little:
            return NSSwapLittleLongLongToHost(self)
        case .big:
            return NSSwapBigLongLongToHost(self)
        }
    }
}
