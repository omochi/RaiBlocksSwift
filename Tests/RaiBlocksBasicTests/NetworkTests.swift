//
//  NetworkTests.swift
//  RaiBlocksBasicTests
//
//  Created by omochimetaru on 2018/02/08.
//

import XCTest
import RaiBlocksBasic

class NetworkTests: XCTestCase {

    func testGenesisBlock() {
        let network = Network.main
        let block = network.genesis.block
        let score: UInt64 = block.work!.score(for: block.account)
        XCTAssertGreaterThanOrEqual(score, network.workScoreThreshold)        
    }

}
