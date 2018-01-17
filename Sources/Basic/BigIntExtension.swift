import Foundation
import BigInt

extension BigUInt {
    public func asData() -> Data {
        return serialize()
    }
    
    public func unitFormat(unitDigitNum: Int, fractionDigitNum: Int) -> String {
        precondition(unitDigitNum >= 0)
        precondition(fractionDigitNum >= 0)
        
        let ten = BigUInt(10)
        
        let roundDigitNum = Swift.max(0, unitDigitNum - fractionDigitNum)
        
        var temp = self
        
        if roundDigitNum > 0 {
            let roundValue = ten.power(roundDigitNum)
            if roundValue / 2 <= self % roundValue {
                temp += roundValue
            }
            
            for _ in 0..<roundDigitNum {
                temp /= ten
            }
        }
        
        let fractionDivider = ten.power(fractionDigitNum)

        let integral = temp / fractionDivider
        var result = integral.description
        
        if fractionDigitNum > 0 {
            let fraction = temp % fractionDivider
            var fractionStr = fraction.description
            if fractionStr.count < fractionDigitNum {
                let zeros = String.init(repeating: "0",
                                        count: fractionDigitNum - fractionStr.count)
                fractionStr = zeros + fractionStr
            }
            
            result += "." + fractionStr
        }
        
        return result
    }
}
