import Foundation
import RaiBlocksBasic
import RaiBlocksSocket

public class BootstrapClient {
    public init(queue: DispatchQueue,
                network: Network,
                messageWriter: MessageWriter)
    {
        self.queue = queue
        self.network = network
        self.messageWriter = messageWriter
        _terminated = false
    }

    public func terminate() {
        _terminate()
        _terminated = true
    }
    
    public func connect(protocolFamily: ProtocolFamily,
                        hostname: String,
                        port: Int,
                        successHandler: @escaping () -> Void,
                        errorHandler: @escaping (Error) -> Void)
    {
        do {
            precondition(_socket == nil)
            
            let socket = try TCPSocket.init(callbackQueue: queue)
            self._socket = socket
            socket.connect(protocolFamily: protocolFamily,
                           hostname: hostname,
                           port: port,
                           successHandler: { successHandler() },
                           errorHandler: { error in
                            self.doError(error, handler: errorHandler) }
            )
        } catch let error {
            doError(error, handler: errorHandler)
        }
    }
    
    public func requestAccount(entryHandler: @escaping (Message.AccountResponseEntry, () -> Void) -> Void,
                               errorHandler: @escaping (Error) -> Void)
    {
        var request = Message.AccountRequest()
        request.age = UInt32.max
        request.count = UInt32.max
        
        _socket!.send(data: messageWriter.write(message: .accountRequest(request), network: network),
                      successHandler: {
                        self.receiveAccount(entryHandler: entryHandler,
                                            errorHandler: errorHandler) },
                      errorHandler: { error in
                        self.doError(error, handler: errorHandler) }
        )
    }
    
    private func receiveAccount(entryHandler: @escaping (Message.AccountResponseEntry, () -> Void) -> Void,
                                errorHandler: @escaping (Error) -> Void)
    {
        _socket!.receive(size: 32 * 2,
                         successHandler: { data in
                            do {
                                let entry = try Message.AccountResponseEntry(from: DataReader(data: data))
                                
                                func next() {
                                    if entry.account == nil { return }
                                    self.receiveAccount(entryHandler: entryHandler, errorHandler: errorHandler)
                                }
                                
                                if self._terminated { return }
                                entryHandler(entry, next)
                            } catch let error {
                                self.doError(error, handler: errorHandler)
                            } },
                         errorHandler: errorHandler)
    }
    
    private func _terminate() {
        _socket?.close()
        _socket = nil
    }

    private func doError(_ error: Error,
                         handler: @escaping (Error) -> Void)
    {
        if _terminated { return }
        _terminate()
        _terminated = true
        handler(error)
    }

    private let queue: DispatchQueue
    private let network: Network
    private let messageWriter: MessageWriter
    private var _terminated: Bool
    private var _errorHandler: ((Error) -> Void)?
    private var _socket: TCPSocket?
}
