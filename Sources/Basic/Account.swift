import Foundation
import BigInt

public class Account : CustomStringConvertible {
    public struct Address {
        public init(data: Data) {
            precondition(data.count == 32, "data must be 32 bytes")
            
            self._data = data
        }
        
        public func asData() -> Data {
            return _data
        }
        
        private let _data: Data
    }
    
    public init(address: Address) {
        self._address = address
        self._headBlock = nil
    }

    public var address: Address {
        return _address
    }
    
    public var headBlock: Block.Hash? {
        return _headBlock
    }
    
    public var description: String {
        let fields = [
            "address=\(address)",
            "headBlock=\(headBlock?.description ?? "")"]
        return "Account(\(fields.joined(separator: ", "))"
    }
    
    private let _address: Address
    private var _headBlock: Block.Hash?
}
