import XCTest
@testable import Basic

import Foundation
import BigInt

class UInt256Tests: XCTestCase {
    func testHex1() throws {
        let a = Data.init(hexString:
            "00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f " +
            "10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f")
        
        let b: [UInt8] = [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
            16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
        ]
        
        XCTAssertEqual(a.map { $0 }, b)
    }
    
    func testHex2() throws {
        let a = Data.init(hexString:
            "00010203 04050607 08090A0B 0C0D0E0F\n" +
            "10111213 14151617 18191A1B 1C1D1E1F")
        
        let b: [UInt8] = [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
            16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
        ]
        
        XCTAssertEqual(a.map { $0 }, b)
    }
    
    func testBigUIntFormat1() throws {
        let a = BigUInt(12340567)
        
        XCTAssertEqual(a.unitFormat(unitDigitNum: 4, fractionDigitNum: 2), "1234.06")
    }
    
    func testBigUIntFormat2() throws {
        let a = BigUInt(9999)
        
        XCTAssertEqual(a.unitFormat(unitDigitNum: 2, fractionDigitNum: 1), "100.0")
    }

    func testBigUIntData1() throws {
        var a = Data.init(hexString: "01 00 00 00 00")
        a.reverse()
        let b = BigUInt.init(a)
        
        XCTAssertEqual(b, BigUInt(1))
    }
    
    func testBigUIntData2() throws {
        let a = BigUInt.init(0x03_00000000)
    
        XCTAssertEqual(a.bitWidth, 34)
    }
    
    func testBigUIntData3() throws {
        let a = BigUInt.init(0x01_02030405)
        let b = a.serialize()
        
        XCTAssertEqual(b.count, 5)
        XCTAssertEqual(b[0], 1)
        XCTAssertEqual(b[1], 2)
        XCTAssertEqual(b[2], 3)
        XCTAssertEqual(b[3], 4)
        XCTAssertEqual(b[4], 5)
    }
    
    static var allTests = [
        ("testHex1", testHex1),
        ("testHex2", testHex2),
        ("testBigUIntFormat1", testBigUIntFormat1),
        ("testBigUIntFormat2", testBigUIntFormat2)
    ]
}
