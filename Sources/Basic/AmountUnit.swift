import BigInt

extension Amount.Unit {
    public var digitNum: Int {
        switch self {
        case .xrb: return 24
        case .rai: return 18
        }
    }
    
    public var amount: Amount {
        switch self {
        case .xrb: return Amount(string: "1000000000000000000000000")
        case .rai: return Amount(string: "1000000000000000000")
        }
    }
}

extension Amount.Unit : CustomStringConvertible {
    public var description: String {
        switch self {
        case .xrb: return "XRB"
        case .rai: return "Rai"
        }
    }
}
