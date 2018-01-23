//
//  AccountTest.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/18.
//

import XCTest
import RaiBlocksBasic

class AccountTests: XCTestCase {
    func testAccountAddress() throws {
        let str1 = "xrb_3arg3asgtigae3xckabaaewkx3bzsh7nwz7jkmjos79ihyaxwphhm6qgjps4"
        let address = try Account.Address.init(string: str1)
        let str2 = address.description
        XCTAssertEqual(str2, str1)
    }


}
