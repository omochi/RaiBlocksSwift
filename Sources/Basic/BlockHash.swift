import Foundation

extension Block.Hash : CustomStringConvertible {
    public var description: String {
        return asData().toHex()
    }
}

extension Block.Hash {
    public init(hexString: String) {
        let data = Data.init(hexString: hexString)
        self.init(data: data)
    }
}

extension Block.Hash : Equatable {}

public func ==(a: Block.Hash, b: Block.Hash) -> Bool {
    return a.asData() == b.asData()
}
