public struct SendBlock : Block {
    public let previous: BlockHash
    public let destination: Account.Address
    public let balance: Amount
    public let signature: Signature
    
    
    public var description: String {
        let fields = [
            "previous=\(previous)",
            "destination=\(destination)",
            "balance=\(balance)"]
        return "SendBlock(\(fields.joined(separator: ", ")))"
    }
}
