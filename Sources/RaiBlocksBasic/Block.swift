import Foundation

public enum Block {
    public struct Hash {
        public init(data: Data) {
            precondition(data.count == 32)
            
            self._data = data
        }
        
        public func asData() -> Data {
            return _data
        }
        
        private let _data: Data
    }
}
