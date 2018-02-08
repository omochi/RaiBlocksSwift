import Foundation
import BigInt

public class Account : CustomStringConvertible {
    public struct Address : DataConvertible, DataWritable, DataReadable {
        public init(data: Data) {
            precondition(data.count == Address.size, "data must be \(Address.size) bytes")
            
            self._data = data
        }

        public init(from reader: DataReader) throws {
            let data = try reader.read(Data.self, size: Address.size)
            self.init(data: data)
        }
        
        public func write(to writer: DataWriter) {
            writer.write(asData())
        }
        
        public func asData() -> Data {
            return _data
        }
        
        public static let size: Int = 32
        
        public static let zero: Address = .init(data: Data.init(count: size))
        
        private let _data: Data
    }
    
    public init(address: Address,
                headBlock: Block.Hash,
                amount: Amount,
                representativeBlock: Block.Hash,
                blockCount: Int) {
        self.address = address
        self.headBlock = headBlock
        self.amount = amount
        self.representativeBlock = representativeBlock
        self.blockCount = blockCount
    }
    
    public let address: Address
    public var headBlock: Block.Hash
    public var amount: Amount
    public var representativeBlock: Block.Hash
    public var blockCount: Int    
    
    public var description: String {
        let fields = [
            "address=\(address)",
            "headBlock=\(headBlock)"]
        return "Account(\(fields.joined(separator: ", "))"
    }
}

extension Account {
    public convenience init(openBlock: Block.Open) {
        fatalError("TODO")
//        self.init(address: openBlock.account,
//                  headBlock: openBlock.hash,
//                  amount: openBlock.source,
//                  representativeBlock: openBlock.representative,
//                  blockCount: 1)
    }
}
