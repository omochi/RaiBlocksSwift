//
//  SocketTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/22.
//

import XCTest
import Basic

class SocketTests: XCTestCase {
    
    func testConnect1() throws {
        let exp = self.expectation(description: "")
        let socket = try TCPSocket.init(callbackQueue: .main)
        socket.connect(endPoint: IPv6.EndPoint.init(address: IPv6.Address.init(string: "2404:6800:4004:800::200e")!,
                                                    port: 80),
                       successHandler: {
                        exp.fulfill()
                        
        },
                       errorHandler: { error in
                        XCTFail()
                        exp.fulfill()
        })
        wait(for: [exp], timeout: 12.0)
    }
    
}
