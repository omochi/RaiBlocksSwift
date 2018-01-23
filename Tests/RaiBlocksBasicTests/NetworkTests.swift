//
//  NetworkTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/20.
//

import XCTest
import RaiBlocksBasic

class NetworkTests: XCTestCase {

    func testNameResolve1() {
        let exp = self.expectation(description: "")
        let task = nameResolve(protocolFamily: .ipv4,
                               hostname: "raiblocks.net",
                               callbackQueue: .main,
                               successHandler: { (addresses) in
                                XCTAssertTrue(addresses.contains { address in
                                    switch address {
                                    case .ipv4(let ep):
                                        return ep.address == IPv4.Address(string: "104.31.68.185")!
                                    default:
                                        return false
                                    }
                                })
                                XCTAssertTrue(addresses.contains { address in
                                    switch address {
                                    case .ipv4(let ep):
                                        return ep.address == IPv4.Address(string: "104.31.69.185")!
                                    default:
                                        return false
                                    }
                                })
                                exp.fulfill()
        },
                               errorHandler: { error in
                                XCTFail(String(describing: error))
                                exp.fulfill()
        })
        let _ = task
        wait(for: [exp], timeout: 10.0)

    }
    
    func testNameResolveCancel1() {
        let exp = self.expectation(description: "")
        let task = nameResolve(protocolFamily: .ipv4,
                               hostname: "raiblocks.net",
                               callbackQueue: .main,
                               successHandler: { (addresses) in
                                XCTFail()
        },
                               errorHandler: { error in
                                XCTFail(String(describing: error))
        })
        task.terminate()
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1.0) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10.0)
    }
    
    func testNameResolve2() {
        let exp = self.expectation(description: "")
        let task = nameResolve(protocolFamily: .ipv4,
                               hostname: "117.104.133.164",
                               callbackQueue: .main,
                               successHandler: { (addresses) in
                                XCTAssertTrue(addresses.contains { address in
                                    switch address {
                                    case .ipv4(let ep):
                                        return ep.address == IPv4.Address(string: "117.104.133.164")!
                                    default:
                                        return false
                                    }
                                })
                                exp.fulfill()
        },
                               errorHandler: { error in
                                XCTFail(String(describing: error))
                                exp.fulfill()
        })
        let _ = task
        wait(for: [exp], timeout: 10.0)
    }


}
