import Foundation
import Blake2
import BigInt

extension Account.Address {
    public func asBigUInt() -> BigUInt {
        return asData().asBigUInt()
    }

    public init(bigUInt: BigUInt) {
        precondition(bigUInt.bitWidth <= 256)
        self.init(data: bigUInt.asData(size: 32))
    }
}

extension Account.Address {
    public var checkValue: BigUInt {
        var hash = Blake2B.compute(data: asData(), outputSize: 5)
        hash.reverse()
        return hash.asBigUInt()
    }
}

extension Account.Address : CustomStringConvertible {
    public var description: String {
        return AccountAddressFormatter.shared.format(address: self)
    }
}

internal struct AccountAddressFormatter {
    public init() {
        chars = "13456789abcdefghijkmnopqrstuwxyz".map { String.init($0) }
    }
    
    public func format(address: Account.Address) -> String {
        let check = address.checkValue
        assert(check.bitWidth <= 40)
        
        var number = address.asBigUInt()
        number <<= 40
        number |= check
        assert(number.bitWidth <= 296)
        
        var str = String.init()
        for _ in 0..<60 {
            let value = Int(number & 0x1F)
            number >>= 5
            str.append(char(for: value))
        }
        assert(number == 0)
        
        str = String.init(str.reversed())
        return "xrb_" + str
    }
    
    public static let shared: AccountAddressFormatter = .init()
    
    private func char(for value: Int) -> String {
        precondition(0 <= value && value < 32)
        return chars[value]
    }
    
    private let chars: [String]
}

internal struct AccountAddressParser {
    public init() {
        let chars = "~0~1234567~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~89:;<=>?@AB~CDEFGHIJK~LMNO~~~~~"
        let codePoints: [UInt32] = chars.unicodeScalars.map { $0.value }
        valueTable = codePoints.map { Int($0) - 0x30 }
        tildeValue = Int("~".unicodeScalars.first!.value)
    }
    
    public func parse(string: String) throws -> Account.Address {
        var string: Substring = string[...]

        guard string.count == 64 else {
            throw GenericError.init(message: "address is invalid length: \(string)")
        }
        
        guard string.hasPrefix("xrb") else {
            throw GenericError.init(message: "address prefix is wrong: \(string)")
        }
        string = string.dropFirst(3)
        
        guard string.hasPrefix("_") || string.hasPrefix("-") else {
            throw GenericError.init(message: "address prefix is wrong: \(string)")
        }
        string = string.dropFirst(1)

        var number = BigUInt(0)
        for scalar in string.unicodeScalars {
            guard let value = self.value(for: scalar) else {
                throw GenericError.init(message: "invalid char in address: \(string)")
            }
            number <<= 5
            number |= BigUInt(value)
        }
        
        let address = Account.Address.init(bigUInt: number >> 40)
        
        let check = number & 0xFF_FF_FF_FF_FF
        guard address.checkValue == check else {
            throw GenericError.init(message: "check hash is invalid: \(string)")
        }
        
        return address
    }
    
    public static let shared: AccountAddressParser = .init()
    
    private func value(for char: Unicode.Scalar) -> Int? {
        let charValue = char.value
        guard 0x30 <= charValue && charValue < 0x80 else {
            return nil
        }
        let value = valueTable[Int(charValue) - 0x30]
        if value == tildeValue {
            return nil
        }
        return value
    }
    
    private let valueTable: [Int]
    private let tildeValue: Int
}

extension Account.Address {
    public init(string: String) throws {
        self = try AccountAddressParser.shared.parse(string: string)
    }
}
