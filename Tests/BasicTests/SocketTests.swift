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
        socket.connect(endPoint: IPv6.EndPoint(address: IPv6.Address(string: "2001:19f0:5801:332:5400:ff:fe50:7ed7")!,
                                               port: 7075),
                       successHandler: { exp.fulfill() },
                       errorHandler:{ error in
                        XCTFail()
                        exp.fulfill()
        })
        wait(for: [exp], timeout: 12.0)
    }
    
    func testWriteRead1() throws {
        let exp = self.expectation(description: "")
        let socket: TCPSocket = try TCPSocket.init(callbackQueue: .main)
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
    
    func testListen1() throws {
        let exp1 = self.expectation(description: "listenSocket")
        
        let listenSocket = try TCPSocket.init(callbackQueue: .main)
        try listenSocket.listen(port: 4567)
        listenSocket.accept(successHandler: { socket in
            let message = "hello client"
            socket.send(data: message.data(using: .utf8)!,
                        successHandler: {
                            exp1.fulfill()
            },
                        errorHandler: { error in
                            XCTFail(String(describing: error))
                            exp1.fulfill()
            })
        },
                            errorHandler: { error in
                                XCTFail(String(describing: error))
                                exp1.fulfill()
        })
        
        let exp2 = self.expectation(description: "clientSocket")
        
        let clientSocket = try TCPSocket.init(callbackQueue: .main)
        clientSocket.connect(endPoint: IPv6.EndPoint(address: IPv6.Address(string: "::1")!,
                                                     port: 4567),
                             successHandler: { 
                                clientSocket.receive(successHandler: { data in
                                    let str = String.init(data: data, encoding: .utf8)!
                                    XCTAssertEqual(str, "hello client")
                                    exp2.fulfill()
                                },
                                                     errorHandler: { error in
                                                        XCTFail(String(describing: error))
                                                        exp2.fulfill()
                                })
        },
                             errorHandler: { error in
                                XCTFail(String(describing: error))
                                exp2.fulfill()
        })
        
        wait(for: [exp1, exp2], timeout: 10.0)
    }
    
}
