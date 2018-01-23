import XCTest
import RaiBlocksBasic

class SecretKeyTests: XCTestCase {
    func testGenerateAddress() throws {
        let secKey = SecretKey.init(data: Data.init(hexString: "34F0A37AAD20F4A260F0A5B3CB3D7FB50673212263E58A380BC10474BB039CE4"))
        
        let account = secKey.generateAddress()
        
        XCTAssertEqual(account.description,
                       "xrb_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpiij4txtdo")
    }
}

