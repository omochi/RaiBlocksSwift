import Foundation
import RaiBlocksBasic

public class BootstrapClient {
    public init(callbackQueue: DispatchQueue) {
        queue = DispatchQueue.init(label: "BootstrapClient.queue")
        self.callbackQueue = callbackQueue
        _terminated = false
    }

    public func terminate() {
        queue.sync {
            _terminate()
            _terminated = true
        }
    }
    
    public func connect(hostname: String,
                        port: Int,
                        successHandler: @escaping () -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        weak var wself = self
        queue.sync {
            do {
                precondition(_socket == nil)
                
                let socket = try TCPSocket.init(callbackQueue: queue)
                self._socket = socket
                socket.connect(protocolFamily: .ipv4,
                               hostname: hostname,
                               port: port,
                               successHandler: {
                                wself?.postCallback { _ in
                                    successHandler()
                                }
                },
                               errorHandler: { (error) in
                                wself?.doError(error, handler: errorHandler)
                })
            } catch let error {
                doError(error, handler: errorHandler)
            }
        }
    }
    
    private func _terminate() {
        _socket?.close()
        _socket = nil
    }
    
    private func postCallback(_ f: @escaping (BootstrapClient) -> Void) {
        weak var wself = self
        
        callbackQueue.async {
            guard let `self` = wself else { return }
            
            guard (self.queue.sync {
                if self._terminated {
                    return false
                }
                return true
            }) else { return }
            
            f(self)
        }
    }
    
    private func doError(_ error: Error,
                         handler: @escaping (Error) -> Void)
    {
        _terminate()
        
        postCallback { `self` in
            self.queue.sync {
                self._terminated = true
            }
            
            handler(error)
        }
    }
    
    private let queue: DispatchQueue
    private let callbackQueue: DispatchQueue
    private var _terminated: Bool
    private var _errorHandler: ((Error) -> Void)?
    private var _socket: TCPSocket?
}
