import Foundation

public struct BlockHash : CustomStringConvertible {
    public init(data: Data) {
        precondition(data.count == 32)
        
        self._data = data
    }
    
    public var description: String {
        return asData().toHex()
    }
    
    public func asData() -> Data {
        return _data
    }
    
    private let _data: Data
}
