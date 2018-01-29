import Foundation
import BigInt
import SQLite

extension Data {
    public func toHex() -> String {
        var ret = String.init()
        for byte in self {
            ret.append(String.init(format: "%02x", byte))
        }
        return ret
    }
    
    public func asBigUInt() -> BigUInt {
        return BigUInt.init(self)
    }
}

internal struct DataHexParser {
    public init() {
        regex = try! NSRegularExpression.init(pattern: "[0-9a-fA-F]{2}", options: [])
    }
    
    public func parse(hexString string: String) -> Data {
        var ret = Data.init()
        
        let nsString = string as NSString
        let matches = regex.matches(in: string, options: [],
                                    range: NSRange.init(location: 0, length: nsString.length))
        for match in matches {
            let byteStr = nsString.substring(with: match.range)
            let byte = UInt8.init(byteStr, radix: 16)!
            ret.append(byte)
        }
        
        return ret
    }

    public static let shared: DataHexParser = .init()

    private let regex: NSRegularExpression
}

extension Data {
    public init(hexString: String) {
        self = DataHexParser.shared.parse(hexString: hexString)
    }
}

extension Data {
    public func asSQLite() -> SQLite.Blob {
        return SQLite.Blob(data: self)
    }
}
