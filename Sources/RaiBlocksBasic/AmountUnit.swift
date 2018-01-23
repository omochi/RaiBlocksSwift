import BigInt

internal class AmountUnitInfo {
    public let digitNum: Int
    public let amount: Amount
    public let string: String
    
    public init(digitNum: Int, string: String) {
        self.digitNum = digitNum
        self.amount = Amount.init(BigUInt(10).power(digitNum))
        self.string = string
    }
    
    public static let xrb = AmountUnitInfo(digitNum: 30, string: "XRB")
    public static let sxrb = AmountUnitInfo(digitNum: 24, string: "rai")
}

extension Amount.Unit {
    internal var info: AmountUnitInfo {
        switch self {
        case .xrb: return AmountUnitInfo.xrb
        case .rai: return AmountUnitInfo.sxrb
        }
    }
    
    public var digitNum: Int {
        return info.digitNum
    }
    
    public var amount: Amount {
        return info.amount
    }
}

extension Amount.Unit : CustomStringConvertible {
    public var description: String {
        return info.string
    }
}
