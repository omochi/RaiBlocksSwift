public struct Work : CustomStringConvertible {
    public init(value: UInt64) {
        self._value = value
    }
    
    public var value: UInt64 {
        return _value
    }
    
    public var description: String {
        return value.description
    }
    
    private let _value: UInt64
}
