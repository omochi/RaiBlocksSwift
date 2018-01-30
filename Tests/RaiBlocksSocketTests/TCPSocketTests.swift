//
//  SocketTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/22.
//

import XCTest
import RaiBlocksSocket

class TCPSocketTests: XCTestCase {
    
    func testConnect1() throws {
        let exp = self.expectation(description: "")
        
        let socket = try TCPSocket.init(callbackQueue: .main)
        socket.connect(endPoint: .ipv4(IPv4.EndPoint(address: IPv4.Address(string: "117.104.133.164")!,
                                                     port: 80)),
                       successHandler: {
                        exp.fulfill() },
                       errorHandler:{ error in
                        XCTFail(String(describing: error))
                        exp.fulfill()
        })
        wait(for: [exp], timeout: 12.0)
    }
    
    func testWriteRead1() throws {
        let exp = self.expectation(description: "")
        let socket: TCPSocket = try TCPSocket.init(callbackQueue: .main)
        var response = Data.init()

        socket.connect(endPoint: .ipv4(IPv4.EndPoint(address: IPv4.Address(string: "117.104.133.164")!,
                                                     port: 80)),
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
            socket.receive(size: nil,
                           successHandler: { data in
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
    
    func testWriteRead2() throws {
        let exp = self.expectation(description: "")
        let socket: TCPSocket = try TCPSocket.init(callbackQueue: .main)
        var response = Data.init()
        
        socket.connect(protocolFamily: .ipv4,
                       hostname: "jprs.jp", port: 80,
                       successHandler: {
                        send()
        },
                       errorHandler: {
                        XCTFail(String(describing: $0))
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
            socket.receive(size: nil,
                           successHandler: { data in
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
//        print(String(data: response, encoding: .utf8)!)
    }
    
    func testListen1() throws {
        let exp1 = self.expectation(description: "listenSocket")
        
        var sockets: [TCPSocket] = []
        
        let listenSocket = try TCPSocket.init(callbackQueue: .main)
        try listenSocket.listen(protocolFamily: .ipv4, port: 4567)
        listenSocket.accept(successHandler: { socket in
            sockets.append(socket)
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
        clientSocket.connect(endPoint: .ipv4(IPv4.EndPoint(address: IPv4.Address(string: "127.0.0.1")!,
                                                           port: 4567)),
                             successHandler: { 
                                clientSocket.receive(size: nil,
                                                     successHandler: { data in
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
