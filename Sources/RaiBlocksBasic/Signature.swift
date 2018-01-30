import Foundation

public struct Signature : DataWritable {
    public init(data: Data) {
        precondition(data.count == Signature.size)
        
        self._data = data
    }
    
    public func write(to writer: DataWriter) {
        writer.write(data: _data)
    }

    public func asData() -> Data {
        return _data
    }
    
    public static let size: Int = 64
    
    public static let zero: Signature = .init(data: .init(count: size))
    
    private let _data: Data
}

extension Signature : CustomStringConvertible {
    public var description: String {
        return asData().toHex()
    }
}

extension Signature {
    public init(hexString: String) {
        self.init(data: Data.init(hexString: hexString))
    }
}
