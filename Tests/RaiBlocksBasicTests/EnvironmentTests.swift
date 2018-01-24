//
//  EnvironmentTests.swift
//  RaiBlocksBasicTests
//
//  Created by omochimetaru on 2018/01/24.
//

import XCTest
import RaiBlocksBasic

class EnvironmentTests: XCTestCase {

    func testTemp1() throws {
        let env = try Environment.createTemporary()
        print(env.dataDir)
        print(env.tempDir)
    }


}
