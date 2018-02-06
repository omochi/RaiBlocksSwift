import Foundation
import RaiBlocksBasic
import RaiBlocksSocket

public class BootstrapClient {
    public init(network: Network,
                messageWriter: MessageWriter,
                callbackQueue: DispatchQueue) {
        self.queue = DispatchQueue.init(label: "BootstrapClient.queue")
        self.network = network
        self.messageWriter = messageWriter
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
                                wself?.postCallback { `self` in
                                    return { successHandler() }
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
    
    public func requestAccount(entryHandler: @escaping (Message.AccountResponseEntry, () -> Void) -> Void,
                               errorHandler: @escaping (Error) -> Void) {
        weak var wself = self
        queue.sync {
            var request = Message.AccountRequest()
            request.age = UInt32.max
            request.count = UInt32.max
            
            _socket!.send(data: messageWriter.write(message: .accountRequest(request), network: network),
                          successHandler: {
                            wself?.receiveAccount(entryHandler: entryHandler,
                                                  errorHandler: errorHandler)
            },
                          errorHandler: { error in
                            wself?.doError(error, handler: errorHandler)
            })
        }
    }
    
    private func receiveAccount(entryHandler: @escaping (Message.AccountResponseEntry, () -> Void) -> Void,
                                errorHandler: @escaping (Error) -> Void)
    {
        weak var wself = self
        
        func next() {
            guard let `self` = wself else { return }
            self.queue.sync {
                self.receiveAccount(entryHandler: entryHandler,
                                    errorHandler: errorHandler)
            }
        }
        
        func nextEnd() {}
        
        _socket!.receive(size: 32 * 2,
                         successHandler: { data in
                            do {
                                let entry = try Message.AccountResponseEntry(from: DataReader(data: data))
                                
                                wself?.postCallback { `self` in
                                    return {
                                        if entry.account == nil {
                                            entryHandler(entry, nextEnd)
                                        } else {
                                            entryHandler(entry, next)
                                        }
                                    }
                                }
                            } catch let error {
                                wself?.doError(error, handler: errorHandler)
                            }
        },
                         errorHandler: errorHandler)
    }
    
    private func _terminate() {
        _socket?.close()
        _socket = nil
    }

    private func doError(_ error: Error,
                         handler: @escaping (Error) -> Void)
    {
        _terminate()
        
        postCallback { `self` in
            self._terminated = true
            
            return { handler(error) }
        }
    }
    
    private func postCallback(_ f: @escaping (BootstrapClient) -> () -> Void) {
        weak var wself = self
        
        callbackQueue.async {
            guard let `self` = wself else { return }
            
            let next: () -> Void = self.queue.sync {
                if self._terminated {
                    return {}
                }
                return f(self)
            }
            
            next()
        }
    }
    
    private let queue: DispatchQueue
    private let network: Network
    private let messageWriter: MessageWriter
    private let callbackQueue: DispatchQueue
    private var _terminated: Bool
    private var _errorHandler: ((Error) -> Void)?
    private var _socket: TCPSocket?
}
