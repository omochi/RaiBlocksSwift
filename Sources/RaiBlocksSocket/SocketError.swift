public struct SocketError : Error, CustomStringConvertible {
    public init(message: String) {
        self.message = message
    }
    
    public var message: String
    
    public var description: String {
        return message
    }
}
