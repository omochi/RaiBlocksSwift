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
        nameResolve(hostname: "raiblocks.net",
                    callbackQueue: .main,
                    resultHandler: { (addresses) in
                        XCTAssertTrue(addresses.contains { $0 == IPv6.Address(string: "2400:cb00:2048:1:0:0:681f:45b9")! })
                        XCTAssertTrue(addresses.contains { $0 == IPv6.Address(string: "2400:cb00:2048:1:0:0:681f:44b9")! })
                        exp.fulfill()
        })
        wait(for: [exp], timeout: 10.0)
    }
    
    func testNameResolveCancel1() {
        let exp = self.expectation(description: "")
        let task = nameResolve(hostname: "raiblocks.net",
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
