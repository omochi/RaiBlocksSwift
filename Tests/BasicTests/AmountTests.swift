//
//  AmountTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/17.
//

import XCTest
import Basic

class AmountTests: XCTestCase {

    func testUnit() {
        var a = Amount.init(value: 123) * Amount.Unit.xrb
        XCTAssertEqual(a.description, "123.000000 XRB")
        
        a += Amount.init(value: 456789) * Amount.Unit.rai
        XCTAssertEqual(a.description, "123.456789 XRB")        
    }

}
