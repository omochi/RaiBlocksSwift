
import XCTest
import RaiBlocksBasic
import RaiBlocksNode

class BootstrapTests: XCTestCase {
    
    func _test1() throws {
        let exp = self.expectation(description: "")
        
        let client = BootstrapClient.init(queue: .main,
                                          network: Network.main,
                                          messageWriter: MessageWriter())
        
        func errorHandler(error: Error) {
            XCTFail(String(describing: error))
            exp.fulfill()
        }
        
        client.connect(protocolFamily: .ipv4,
                       hostname: "rai.raiblocks.net",
                       port: 7075,
                       successHandler: { connectHandler() },
                       errorHandler: errorHandler)
        
        wait(for: [exp], timeout: 3600 * 24)
        
        func connectHandler() {
            var i = 0
            client.requestAccount(entryHandler: { (entry, next) in
                print("\(i), \(entry.account?.description ?? ""), \(entry.headBlock?.description ?? "")")
                i += 1
                next()
            },
                                  errorHandler: errorHandler)
        }
    }
}

