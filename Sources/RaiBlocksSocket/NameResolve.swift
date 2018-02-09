//
//  NameResolver.swift
//  Basic
//
//  Created by omochimetaru on 2018/01/20.
//

import Foundation

public class NameResolveTask {
    public init(queue: DispatchQueue,
                protocolFamily: ProtocolFamily,
                hostname: String,
                successHandler: @escaping ([EndPoint]) -> Void,
                errorHandler: @escaping (Error) -> Void)
    {
        self.queue = queue
        self.terminated = false
        
        weak var wself = self
        
        DispatchQueue.global().async {
            do {
                let result = try nameResolveSync(protocolFamily: protocolFamily,
                                                 hostname: hostname)
                wself?.postCallback {
                    successHandler(result)
                }
            } catch let error {
                wself?.postCallback {
                    errorHandler(error)
                }
            }
        }
    }
    
    deinit {
        terminate()
    }
    
    public func terminate() {
        terminated = true
    }
    
    private func postCallback(_ handler: @escaping () -> Void) {
        weak var wself = self
        
        queue.async {
            guard let `self` = wself else { return }
            if self.terminated { return }
            handler()
        }
    }
    
    private let queue: DispatchQueue
    private var terminated: Bool
}

public func nameResolve(queue: DispatchQueue,
                        protocolFamily: ProtocolFamily,
                        hostname: String,
                        successHandler: @escaping ([EndPoint]) -> Void,
                        errorHandler: @escaping (Error) -> Void)
    -> NameResolveTask
{
    return NameResolveTask(queue: queue,
                           protocolFamily: protocolFamily,
                           hostname: hostname,
                           successHandler: successHandler,
                           errorHandler: errorHandler)
}

private func nameResolveSync(protocolFamily: ProtocolFamily,
                             hostname: String)
    throws -> [EndPoint]
{
    var hint: addrinfo = .init()
    hint.ai_family = protocolFamily.value
    hint.ai_protocol = IPPROTO_TCP
    switch protocolFamily {
    case .ipv6:
        hint.ai_flags = AI_V4MAPPED
    default:
        break
    }
    
    var firstAddrinfo: UnsafeMutablePointer<addrinfo>? = nil
    let st = getaddrinfo(hostname, nil, &hint, &firstAddrinfo)
    if st != 0 {
        let message = String.init(cString: gai_strerror(st))
        throw SocketError.init(message: "getaddrinfo(\(hostname)): \(message)")
    }
    
    var result: [EndPoint] = []
    
    var addrinfoOpt = firstAddrinfo
    while let addrinfo = addrinfoOpt {
        if let pf = ProtocolFamily(value: addrinfo.pointee.ai_family) {
            let endPoint = EndPoint.init(protocolFamily: pf,
                                               sockAddr: addrinfo.pointee.ai_addr)
            result.append(endPoint)
        }

        addrinfoOpt = addrinfo.pointee.ai_next
    }
    freeaddrinfo(firstAddrinfo)
    
    return result
}
