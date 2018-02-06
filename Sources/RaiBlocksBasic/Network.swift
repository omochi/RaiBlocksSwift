//
//  Network.swift
//  RaiBlocksBasic
//
//  Created by omochimetaru on 2018/02/06.
//

import Foundation

public class Network : CustomStringConvertible {
    public let name: String
    public let magicNumber: UInt16
    public let peerPort: Int
    public let initialPeerHostnames: [String]
    
    public init(name: String,
                magicNumber: UInt16,
                peerPort: Int,
                initialPeerHostnames: [String])
    {
        self.name = name
        self.magicNumber = magicNumber
        self.peerPort = peerPort
        self.initialPeerHostnames = initialPeerHostnames
    }
    
    public var description: String {
        return "\(name)"
    }
    
    public static let main = Network(name: "main",
                                     magicNumber: UInt16(Unicode.Scalar("R")!.value) << 8 |
                                        UInt16(Unicode.Scalar("C")!.value),
                                     peerPort: 7075,
                                     initialPeerHostnames: ["rai.raiblocks.net"])
}
