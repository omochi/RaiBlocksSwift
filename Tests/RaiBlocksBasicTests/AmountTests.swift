//
//  AmountTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/17.
//

import XCTest
import RaiBlocksBasic

class AmountTests: XCTestCase {

    func testUnit1() {
        var a = Amount(123) * Amount.Unit.xrb
        XCTAssertEqual(a.description, "123.000000 XRB")
        
        a += Amount(456789) * Amount.Unit.rai
        XCTAssertEqual(a.description, "123.456789 XRB")        
    }

    func testUnit2() {
        var a = Amount(123, unit: .xrb)
        XCTAssertEqual(a.description, "123.000000 XRB")
        
        a += Amount(456789, unit: .rai)
        XCTAssertEqual(a.description, "123.456789 XRB")
    }
    
    func testUnit3() {
        let a = Amount("1000000000000000000000000")
        XCTAssertEqual(a.description, "0.000001 XRB")
        XCTAssertEqual(a.format(unit: .rai, fraction: 0), "1 rai")
    }
}
