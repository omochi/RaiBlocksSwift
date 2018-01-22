//
//  NameResolver.swift
//  Basic
//
//  Created by omochimetaru on 2018/01/20.
//

import Foundation

public class NameResolveTask {
    public init(hostname: String,
                callbackQueue: DispatchQueue,
                resultHandler: @escaping ([IPv6.Address]) -> Void)
    {
        self.queue = DispatchQueue.init(label: "NameResolveTask")
        self.terminated = false
        
        DispatchQueue.global().async {
            let result = nameResolveSync(hostname: hostname)
            
            callbackQueue.async {
                let terminated = self.queue.sync { self.terminated }
                if terminated {
                    return
                }
                
                resultHandler(result)
            }
        }
    }
    
    public func terminate() {
        queue.sync {
            self.terminated = true
        }
    }
    
    private let queue: DispatchQueue
    private var terminated: Bool
    
}

@discardableResult
public func nameResolve(hostname: String,
                        callbackQueue: DispatchQueue,
                        resultHandler: @escaping ([IPv6.Address]) -> Void)
    -> NameResolveTask
{
    return NameResolveTask.init(hostname: hostname,
                                callbackQueue: callbackQueue,
                                resultHandler: resultHandler)
}

private func nameResolveSync(hostname: String) -> [IPv6.Address] {
    var hint: addrinfo = .init()
    hint.ai_flags = AI_V4MAPPED
    hint.ai_family = PF_INET6
    hint.ai_protocol = IPPROTO_TCP
    
    var firstAddrinfo: UnsafeMutablePointer<addrinfo>? = nil
    let ret = getaddrinfo(hostname, nil, &hint, &firstAddrinfo)
    assert(ret == 0)
    
    var result: [IPv6.Address] = []
    
    var addrinfoOpt = firstAddrinfo
    while let addrinfo = addrinfoOpt {
        if addrinfo.pointee.ai_family == PF_INET6 {
            addrinfo.pointee.ai_addr!.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { addr in
                let address = IPv6.Address.init(addr: addr.pointee.sin6_addr)
                result.append(address)
            }
        }
        
        addrinfoOpt = addrinfo.pointee.ai_next
    }
    freeaddrinfo(firstAddrinfo)
    
    return result
}
