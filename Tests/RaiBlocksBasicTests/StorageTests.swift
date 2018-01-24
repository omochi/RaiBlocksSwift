//
//  StorageTests.swift
//  RaiBlocksBasicTests
//
//  Created by omochimetaru on 2018/01/24.
//

import XCTest
import RaiBlocksBasic

class StorageTests: XCTestCase {
    func test1() throws {
        let env = try Environment.createTemporary()
        let storage = try Storage.init(dataDir: env.dataDir)
        print(storage.ledgerDBPath)
    }

}
