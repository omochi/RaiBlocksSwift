//
//  NameResolver.swift
//  Basic
//
//  Created by omochimetaru on 2018/01/20.
//

import Foundation

public class NameResolveTask {
    public init(protocolFamily: SocketProtocolFamily,
                hostname: String,
                callbackQueue: DispatchQueue,
                resultHandler: @escaping ([SocketEndPoint]) -> Void)
    {
        self.queue = DispatchQueue.init(label: "NameResolveTask")
        self.terminated = false
        
        weak var wself = self
        
        DispatchQueue.global().async {
            let result = nameResolveSync(protocolFamily: protocolFamily,
                                         hostname: hostname)
            
            callbackQueue.async {
                guard let sself = wself else {
                    return
                }
                
                let terminated = sself.queue.sync { sself.terminated }
                if terminated {
                    return
                }
                
                resultHandler(result)
            }
        }
    }
    
    deinit {
        terminate()
    }
    
    public func terminate() {
        queue.sync {
            self.terminated = true
        }
    }
    
    private let queue: DispatchQueue
    private var terminated: Bool
    
}

public func nameResolve(protocolFamily: SocketProtocolFamily,
                        hostname: String,
                        callbackQueue: DispatchQueue,
                        resultHandler: @escaping ([SocketEndPoint]) -> Void)
    -> NameResolveTask
{
    return NameResolveTask.init(protocolFamily: protocolFamily,
                                hostname: hostname,
                                callbackQueue: callbackQueue,
                                resultHandler: resultHandler)
}

private func nameResolveSync(protocolFamily: SocketProtocolFamily,
                             hostname: String) -> [SocketEndPoint] {
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
    let ret = getaddrinfo(hostname, nil, &hint, &firstAddrinfo)
    assert(ret == 0)
    
    var result: [SocketEndPoint] = []
    
    var addrinfoOpt = firstAddrinfo
    while let addrinfo = addrinfoOpt {
        if let pf = SocketProtocolFamily(value: addrinfo.pointee.ai_family) {
            let endPoint = SocketEndPoint.init(protocolFamily: pf,
                                               sockAddr: addrinfo.pointee.ai_addr)
            result.append(endPoint)
        }

        addrinfoOpt = addrinfo.pointee.ai_next
    }
    freeaddrinfo(firstAddrinfo)
    
    return result
}
