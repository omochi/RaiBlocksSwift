import Foundation
import BigInt
import SQLite

public struct Amount {
    public enum Unit {
        case xrb
        case rai
    }
    
    public init(_ value: Int) {
        precondition(value >= 0)
        
        self.init(BigUInt(value))
    }
    
    public init(_ value: Int, unit: Unit) {
        self = Amount(value) * unit
    }
        
    public init(_ value: BigUInt) {
        precondition(value.bitWidth <= 128)
        
        self._value = value
    }
    
    public init(_ string: String) {
        let value = BigUInt.init(string)!
        self.init(value)
    }
    
    public var value: BigUInt {
        return _value
    }
    
    private var _value: BigUInt
}

extension Amount : CustomStringConvertible {
    public var description: String {
        return format(unit: .xrb, fraction: 6)
    }
    
    public func format(unit: Unit, fraction: Int) -> String {
        return value.unitFormat(unitDigitNum: unit.digitNum,
                                fractionDigitNum: fraction) +
            " " + unit.description
    }
}

extension Amount : Equatable {}

public func ==(a: Amount, b: Amount) -> Bool {
    return a.value == b.value
}

extension Amount : Comparable {}

public func <(a: Amount, b: Amount) -> Bool {
    return a.value < b.value
}

public func +(a: Amount, b: Amount) -> Amount {
    return Amount(a.value + b.value)
}

public func +=(a: inout Amount, b: Amount) {
    a = a + b
}

public func -(a: Amount, b: Amount) -> Amount {
    return Amount(a.value - b.value)
}

public func -=(a: inout Amount, b: Amount) {
    a = a - b
}

public func *(a: Amount, b: Amount) -> Amount {
    return Amount(a.value * b.value)
}

public func *=(a: inout Amount, b: Amount) {
    a = a * b
}

public func *(a: Amount, b: Amount.Unit) -> Amount {
    return a * b.amount
}

public func *=(a: inout Amount, b: Amount.Unit) {
    a = a * b
}

extension Amount : DataWritable {
    public init(data: Data) {
        self.init(data.asBigUInt())
    }
    
    public func write(to writer: DataWriter) {
        writer.write(data: value.asData(size: 16))
    }
    
    public func asData() -> Data {
        return value.asData(size: 16)
    }
}
