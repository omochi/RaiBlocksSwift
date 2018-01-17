import Foundation

public class Account : CustomStringConvertible {
    public struct Address {
        public init(data: Data) {
            precondition(data.count == 32)
            
            _data = data
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
    
    public var headBlock: BlockHash? {
        return _headBlock
    }
    
    public var description: String {
        let fields = [
            "address=\(address)",
            "headBlock=\(headBlock?.description ?? "")"]
        return "Account(\(fields.joined(separator: ", "))"
    }
    
    private let _address: Address
    private var _headBlock: BlockHash?
}
