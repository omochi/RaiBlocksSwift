import Foundation
import BigInt

public struct Amount {
    public enum Unit {
        case xrb
        case rai
    }
    
    public init(value: Int) {
        precondition(value >= 0)
        
        self.init(value: BigUInt(value))
    }
        
    public init(value: BigUInt) {
        precondition(value.bitWidth <= 128)
        
        self._value = value
    }
    
    public init(string: String) {
        let value = BigUInt.init(string)!
        self.init(value: value)
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

public func +(a: Amount, b: Amount) -> Amount {
    return Amount.init(value: a.value + b.value)
}

public func +=(a: inout Amount, b: Amount) {
    a = a + b
}

public func -(a: Amount, b: Amount) -> Amount {
    return Amount.init(value: a.value - b.value)
}

public func -=(a: inout Amount, b: Amount) {
    a = a - b
}

public func *(a: Amount, b: Amount) -> Amount {
    return Amount.init(value: a.value * b.value)
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
