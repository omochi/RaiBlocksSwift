//
//  LedgerTests.swift
//  RaiBlocksBasicTests
//
//  Created by omochimetaru on 2018/02/08.
//

import XCTest
import RaiBlocksBasic

class LedgerTests: XCTestCase {
    func testInit() {
        let queue = DispatchQueue(label: "queue")
        let fileSystem = try! FileSystem.createTemporary()
        let network = Network.main
        
        do {
            let storage = try! Storage(fileSystem: fileSystem, network: network)
            let _ = try! Ledger(queue: queue,
                                loggerConfig: Logger.Config(),
                                network: network,
                                storage: storage)
        }
        
        print(fileSystem.dataDir)
    }
}
