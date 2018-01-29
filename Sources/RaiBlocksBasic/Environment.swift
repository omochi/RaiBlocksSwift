//
//  Environment.swift
//  RaiBlocksBasic
//
//  Created by omochimetaru on 2018/01/24.
//

import Foundation
import RaiBlocksRandom

public class Environment {
    public init(dataDir: FilePath,
                tempDir: FilePath)
    {
        self.dataDir = dataDir
        self.tempDir = tempDir
    }
    
    public let dataDir: FilePath
    public let tempDir: FilePath
    
    public func createTempDir() throws -> FilePath {
        let dir = tempDir + String(format: "%08x", Random.getUInt32())
        try dir.createDirectory(intermediates: false)
        return dir
    }
    
    public static func createTemporary() throws -> Environment {
        let root = FilePath(NSTemporaryDirectory()) +
            String(format: "RaiBlocksSwift/temp-env-%08x", Random.getUInt32())

        let dataDir = root + "data"
        
        let tempDir = root + "temp"

        try root.createDirectory(intermediates: true)
        try dataDir.createDirectory(intermediates: false)
        try tempDir.createDirectory(intermediates: false)
        
        return Environment.init(dataDir: dataDir,
                                tempDir: tempDir)
    }
}
