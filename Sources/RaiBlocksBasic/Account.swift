import Foundation
import BigInt

public class Account : CustomStringConvertible {
    public struct Address : DataWritable, DataReadable {
        public init(data: Data) {
            precondition(data.count == Address.size, "data must be \(Address.size) bytes")
            
            self._data = data
        }
        
        public init() {
            self.init(data: Data.init(count: Address.size))
        }
        
        public init(from reader: DataReader) throws {
            let data = try reader.read(Data.self, size: 32)
            self.init(data: data)
        }
        
        public func write(to writer: DataWriter) {
            writer.write(data: _data)
        }
        
        public func asData() -> Data {
            return _data
        }
        
        public static let size: Int = 32
        
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
