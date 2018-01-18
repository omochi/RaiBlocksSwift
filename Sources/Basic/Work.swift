public struct Work {
    public init(_ value: UInt64) {
        self._value = value
    }
    
    public var value: UInt64 {
        return _value
    }
        
    private let _value: UInt64
}

extension Work : CustomStringConvertible {
    public var description: String {
        return value.description
    }
}
