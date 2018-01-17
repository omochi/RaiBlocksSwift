import XCTest
@testable import Basic

import Foundation

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

    static var allTests = [
        ("testHex1", testHex1),
        ("testHex2", testHex2),
    ]
}
