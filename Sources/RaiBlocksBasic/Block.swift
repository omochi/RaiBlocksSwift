import Foundation

public enum Block {
    public struct Hash : DataWritable, DataReadable {
        public init(data: Data) {
            precondition(data.count == 32)
            
            self._data = data
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
        
        private let _data: Data
    }
    
    public enum Kind : UInt8 {
        case invalid = 0
        case notABlock
        case send
        case receive
        case open
        case change
    }
}
