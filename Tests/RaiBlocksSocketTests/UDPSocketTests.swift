//
//  UDPSocketTests.swift
//  RaiBlocksSocketTests
//
//  Created by omochimetaru on 2018/01/30.
//

import XCTest
import RaiBlocksSocket

class UDPSocketTests: XCTestCase {

    func testSendBack1() throws {
        var exp = self.expectation(description: "")
        var socket0: UDPSocket!
        var socket0Port: Int!
        var socket1: UDPSocket!
        var socket1Port: Int!
        
        func errorHandler(error: Error) {
            XCTFail("\(error)")
            exp.fulfill()
        }

        func next1() {
            socket0 = UDPSocket.init(callbackQueue: .main)
            try! socket0.open(protocolFamily: .ipv4)
            
            socket1 = UDPSocket.init(callbackQueue: .main)
            try! socket1.open(protocolFamily: .ipv4)
            
            let msg = "punch\n"
            socket0.send(data: msg.data(using: .utf8)!,
                         endPoint: .ipv4(.init(address: IPv4.Address(string: "127.0.0.1")!, port: 9999)),
                         successHandler: { size in
                            XCTAssertEqual(size, 6)
                            next2()
            },
                         errorHandler: errorHandler)
        }
        
        func next2() {
            socket0Port = try! socket0.getLocalEndPoint().port
            
            let msg = "hello\n"
            socket1.send(data: msg.data(using: .utf8)!,
                         endPoint: .ipv4(.init(address: IPv4.Address(string: "127.0.0.1")!, port: socket0Port)),
                         successHandler: { size in
                            XCTAssertEqual(size, 6)
                            next3()
            },
                         errorHandler: errorHandler)
        }
        
        func next3() {
            socket1Port = try! socket1.getLocalEndPoint().port
            
            socket0.receive(size: 100,
                            successHandler: { (data, ep) in
                                let msg = String(data: data, encoding: .utf8)!
                                XCTAssertEqual(msg, "hello\n")
                                
                                XCTAssertEqual(ep, .ipv4(.init(address: IPv4.Address(string: "127.0.0.1")!,
                                                               port: socket1Port)))
                                next4()
            },
                            errorHandler: errorHandler)
        }
        
        func next4() {
            socket0 = nil
            socket1 = nil
            exp.fulfill()
        }
        
        next1()
        wait(for: [exp], timeout: 10)
    }


}
