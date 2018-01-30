import Foundation

public class MessageClient {
    public init(callbackQueue: DispatchQueue) {
        self.callbackQueue = callbackQueue
    }
    
    
    
    private let callbackQueue: DispatchQueue
//    private let socket: TCPSock
}
