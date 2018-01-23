//
//  NetworkTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/20.
//

import XCTest
import Basic

class NetworkTests: XCTestCase {

    func testNameResolve1() {
        let exp = self.expectation(description: "")
        let task = nameResolve(protocolFamily: .ipv4,
                               hostname: "raiblocks.net",
                               callbackQueue: .main,
                               resultHandler: { (addresses) in
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
        })
        let _ = task
        wait(for: [exp], timeout: 10.0)

    }
    
    func testNameResolveCancel1() {
        let exp = self.expectation(description: "")
        let task = nameResolve(protocolFamily: .ipv4,
                               hostname: "raiblocks.net",
                               callbackQueue: .main,
                               resultHandler: { (addresses) in
                                XCTFail()
        })
        task.terminate()
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1.0) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10.0)
    }


}
