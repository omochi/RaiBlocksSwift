import XCTest
import Basic

class ED25519Tests: XCTestCase {
    func testGeneratePublicKey() throws {
        let secKey = ED25519.SecretKey.init(data: Data.init(hexString: "34F0A37AAD20F4A260F0A5B3CB3D7FB50673212263E58A380BC10474BB039CE4"))
        
        let pubKey = secKey.generatePublicKey()
        
        XCTAssertEqual(pubKey.asData(), Data.init(hexString: "B0311EA55708D6A53C75CDBF88300259C6D018522FE3D4D0A242E431F9E8B6D0"))
        
        let account = Account.Address.init(data: pubKey.asData())
        
        XCTAssertEqual(account.description,
                       "xrb_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpiij4txtdo")
    }
}

