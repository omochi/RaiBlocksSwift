//
//  Network.swift
//  RaiBlocksBasic
//
//  Created by omochimetaru on 2018/02/06.
//

import Foundation
import BigInt

public class Network : CustomStringConvertible {
    public struct Genesis {
        public let account: Account
        public let block: Block.Open
    }
    
    public let name: String
    public let magicNumber: UInt16
    public let workScoreThreshold: UInt64
    public let peerPort: Int
    public let initialPeerHostnames: [String]
    public let genesis: Genesis
    
    public init(name: String,
                magicNumber: UInt16,
                workScoreThreshold: UInt64,
                peerPort: Int,
                initialPeerHostnames: [String],
                genesis: Genesis)
    {
        self.name = name
        self.magicNumber = magicNumber
        self.workScoreThreshold = workScoreThreshold
        self.peerPort = peerPort
        self.initialPeerHostnames = initialPeerHostnames
        self.genesis = genesis
    }
    
    public var description: String {
        return "\(name)"
    }
    
    public static let main: Network = {
        let magicNumber = UInt16(Unicode.Scalar("R")!.value) << 8 |
            UInt16(Unicode.Scalar("C")!.value)
        
        let genesis: Genesis = {
            let address = try! Account.Address(string: "xrb_3t6k35gi95xu6tergt6p69ck76ogmitsa8mnijtpxm9fkcm736xtoncuohr3")
            let amount = Amount(BigUInt(2).power(128) - 1)
            let signatureHex = [
                "9F0C933C8ADE004D808EA1985FA746A7E95BA2A38F867640F53EC8F180BDFE9E",
                "2C1268DEAD7C2664F356E37ABA362BC58E46DBA03E523A7B5A19E4B6EB12BB02"].joined()
            let work = Work(data: Data(hexString: "62f05417dd3fb691").reversedData())
            let block = Block.Open(source: Block.Hash(data: address.asData()),
                                          representative: address,
                                          account: address,
                                          signature: Signature(data: Data(hexString: signatureHex)),
                                          work: work)
            let account = Account.init(address: address,
                                       headBlock: block.hash,
                                       amount: amount,
                                       representativeBlock: block.hash,
                                       blockCount: 1)
            return Genesis(account: account, block: block)
        }()
        
        return Network(name: "main",
                       magicNumber: magicNumber,
                       workScoreThreshold: 0xFFFFFFC000000000,
                       peerPort: 7075,
                       initialPeerHostnames: ["rai.raiblocks.net"],
                       genesis: genesis)
    }()
}
