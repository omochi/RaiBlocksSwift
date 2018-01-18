//
//  BlockTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/18.
//

import XCTest
import Basic
import BigInt

class BlockTests: XCTestCase {
    
    
    func testSendBlockHash1() throws {
        let prev = Block.Hash(hexString: "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9")
        let dest = try Account.Address(string: "xrb_3d69nxbox9qiokkxduazombodwj73mpegrbne1dq1884d37iodtbwnqr163p")
        let amount = Amount(4459900, unit: .sxrb)
        
        var blake = Blake2B.init(outputSize: 32)
        blake.update(data: prev.asData())
        blake.update(data: dest.asData())
        blake.update(data: amount.asData())
        let hash = Block.Hash.init(data: blake.finalize())
        
        XCTAssertEqual(hash,
                       Block.Hash(hexString: "CF1CC942B05DBB611CF9979D2E7F5C6DD4042B426C99C1C5CE5AD784065A3F85"))
    }
    
    func testSendBlockHash2() throws {
        let block = SendBlock.init(previous: Block.Hash(hexString: "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9"),
                                   destination: try Account.Address(string: "xrb_3d69nxbox9qiokkxduazombodwj73mpegrbne1dq1884d37iodtbwnqr163p"),
                                   balance: Amount(4459900, unit: .sxrb),
                                   work: Work(0),
                                   signature: Signature(data: Data.init(count: 64)))
        let hash = block.hash
        
        XCTAssertEqual(hash,
                       Block.Hash(hexString: "CF1CC942B05DBB611CF9979D2E7F5C6DD4042B426C99C1C5CE5AD784065A3F85"))
    }

}
