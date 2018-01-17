import Foundation

public struct BlockHash {
    public init(data: Data) {
        precondition(data.count == 32)
        
        self._data = data
    }

    public func asData() -> Data {
        return _data
    }
    
    private let _data: Data
}

extension BlockHash : CustomStringConvertible {
    public var description: String {
        return asData().toHex()
    }
}
