//
//  DispatchQueueTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/20.
//

import XCTest

class DispatchQueueTests: XCTestCase {

    func _testManyLongTask() {

        var exps: [XCTestExpectation] = []
        
        func start(index: Int) {
            let queue = DispatchQueue.init(label: "queue[\(index)]")
            let exp = expectation(description: "")
            exps.append(exp)
            queue.async {
                var x: UInt64 = 0x1234567812345678
                for i in 0..<10 {
                    for _ in 0..<10000 {
                        for _ in 0..<10000 {
                            x += 1
                        }
                    }
                    print("task[\(index)] \(i+1)/10")
                }
                
                exp.fulfill()
            }
        }
        
        for index in 0..<32 {
            start(index: index)
        }
        
        wait(for: exps, timeout: 1000)
    }



}
