//
//  BlockTests.swift
//  BasicTests
//
//  Created by omochimetaru on 2018/01/18.
//

import XCTest
import RaiBlocksBasic
import BigInt

class BlockTests: XCTestCase {
    func testSendBlockHash1() {
        let prev = Block.Hash(hexString: "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9")
        let dest = try! Account.Address(string: "xrb_3d69nxbox9qiokkxduazombodwj73mpegrbne1dq1884d37iodtbwnqr163p")
        let amount = Amount(4459900, unit: .rai)
        
        let blake = Blake2B.init(outputSize: 32)
        blake.update(data: prev.asData())
        blake.update(data: dest.asData())
        blake.update(data: amount.asData())
        let hash = Block.Hash.init(data: blake.finalize())
        
        XCTAssertEqual(hash,
                       Block.Hash(hexString: "CF1CC942B05DBB611CF9979D2E7F5C6DD4042B426C99C1C5CE5AD784065A3F85"))
    }
    
    func testSendBlockHash2() {
        let block = Block.Send(previous: Block.Hash(hexString: "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9"),
                               destination: try! Account.Address(string: "xrb_3d69nxbox9qiokkxduazombodwj73mpegrbne1dq1884d37iodtbwnqr163p"),
                               balance: Amount(4459900, unit: .rai))
        let hash = block.hash
        
        XCTAssertEqual(hash,
                       Block.Hash(hexString: "CF1CC942B05DBB611CF9979D2E7F5C6DD4042B426C99C1C5CE5AD784065A3F85"))
    }
    
    func testSendBlockSignature() {
        let block = Block.Send(previous: Block.Hash(hexString: "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9"),
                               destination: try! Account.Address(string: "xrb_3d69nxbox9qiokkxduazombodwj73mpegrbne1dq1884d37iodtbwnqr163p"),
                               balance: Amount(4459900, unit: .rai),
                               signature: Signature(hexString: "CB49AD73271DA6C58ADFCD74A2F254DBF5CB58E50E1DA0DECA4796F446D73E894EEDFE01E77D8858A3F2BD8796AE8CAF018FAAB8CA2E96867088E7E1AE192B08"))
        
        let address = try! Account.Address(string: "xrb_151kndxz7cjx5ygem9am7m8wk669ingtw8dj1e6ca31gzsftj3i3oiw5p5tk")
        
        XCTAssertTrue(block.verifySignature(address: address))
    }
    
    func testWorkScore1() {
        let hashHex = "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9"
        let workHex = "24334bb782f6fade"
        
        let blake = Blake2B.init(outputSize: 8)
        blake.update(data: Data(Data.init(hexString: workHex).reversed()))
        blake.update(data: Data(Data.init(hexString: hashHex)))
        let data = blake.finalize()
        let sc = data.withUnsafeBytes { (p: UnsafePointer<UInt64>) in
            p.pointee
        }
        XCTAssertGreaterThanOrEqual(sc, 0xFFFFFFC000000000)
    }
    
    func testWorkScore2() {
        let hash = Block.Hash.init(hexString: "D7E659B9C448B241157BECA5DDA1B4F451555AE16149D161013C028DC36800A9")
        let work = Work.init(0x24334bb782f6fade)
        let score = work.score(for: hash)
        XCTAssertGreaterThanOrEqual(score, 0xFFFFFFC000000000)
    }

}
