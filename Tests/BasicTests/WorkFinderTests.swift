//
//  WorkFinderTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/19.
//

import XCTest
import Basic

class WorkFinderTests: XCTestCase {

    func testFinder1() {
        var exps: [XCTestExpectation] = []
        let thresh: UInt64 = 0xFFFF0000_00000000
        let finder = WorkFinder.init(callbackQueue: DispatchQueue.main, workerNum: 2)
        let hash = Block.Hash(hexString: "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9")
        
        var count = 0
        
        let exp1 = expectation(description: "")
        exps.append(exp1)
        finder.find(hash: hash,
                    threshold: thresh,
                    completeHandler: { work in
                        count += 1
                        XCTAssertEqual(count, 1)
                        XCTAssertGreaterThanOrEqual(hash.score(of: work), thresh)
                        exp1.fulfill()
        })
        
        let exp2 = expectation(description: "")
        exps.append(exp2)
        finder.find(hash: hash,
                    threshold: thresh,
                    completeHandler: { work in
                        count += 1
                        XCTAssertEqual(count, 2)
                        XCTAssertGreaterThanOrEqual(hash.score(of: work), thresh)
                        exp2.fulfill()
        })
        
        let exp3 = expectation(description: "")
        exps.append(exp3)
        finder.find(hash: hash,
                    threshold: thresh,
                    completeHandler: { work in
                        count += 1
                        XCTAssertEqual(count, 3)
                        XCTAssertGreaterThanOrEqual(hash.score(of: work), thresh)
                        exp3.fulfill()
        })
        
        wait(for: exps, timeout: 10.0)
    }
    



}
