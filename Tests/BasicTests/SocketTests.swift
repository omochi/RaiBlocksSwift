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
        socket.connect(endPoint: IPv6.EndPoint(address: IPv6.Address(string: "2001:218:3001:7:0:0:0:b0")!,
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
    
    func testWriteRead1() throws {
        let exp = self.expectation(description: "")
        let socket = try TCPSocket.init(callbackQueue: .main)
        var response = Data.init()
        
        socket.connect(endPoint: IPv6.EndPoint(address: IPv6.Address(string: "2001:218:3001:7::b0")!,
                                               port: 80),
                       successHandler: {
                        send()
        },
                       errorHandler: { error in
                        XCTFail(String(describing: error))
                        exp.fulfill()
        })
        
        func send() {
            let request: String = [
                "GET / HTTP/1.1",
                "Host: jprs.jp",
                "User-Agent: SocketTest",
                "Accept: */*",
                "Connection: close",
                "", ""].joined(separator: "\r\n")
            
            socket.send(data: request.data(using: .utf8)!,
                        successHandler: {
                            receive()
            },
                        errorHandler: { error in
                            XCTFail(String(describing: error))
                            exp.fulfill()
            })
        }
        
        func receive() {
            socket.receive(successHandler: { data in
                if data.count == 0 {
                    exp.fulfill()
                } else {
                    response.append(data)
                    receive()
                }
            },
                           errorHandler: { error in
                            XCTFail(String(describing: error))
                            exp.fulfill()
            })
        }
        
        wait(for: [exp], timeout: 10.0)
    }
    
}
