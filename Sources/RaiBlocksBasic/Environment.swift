//
//  Environment.swift
//  RaiBlocksBasic
//
//  Created by omochimetaru on 2018/01/24.
//

import Foundation
import RaiBlocksRandom

public struct Environment {
    public init(dataDir: FilePath,
                tempDir: FilePath) throws
    {
        self.dataDir = dataDir
        self.tempDir = tempDir
        
        try dataDir.createDirectory(intermediates: true)
        try tempDir.createDirectory(intermediates: true)
    }
    
    public var dataDir: FilePath
    public var tempDir: FilePath
    
    public func createTempDir() throws -> FilePath {
        let dir = tempDir + String(format: "%08x", Random.getUInt32())
        try dir.createDirectory(intermediates: false)
        return dir
    }
    
    public static func createDefault() throws -> Environment {
        let fm = FileManager.default
        let supportDir = FilePath(url: fm.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory,
                                               in: FileManager.SearchPathDomainMask.userDomainMask)[0])
        let dataDir = supportDir + "RaiBlocksSwift"
        let tempDir = FilePath(NSTemporaryDirectory()) +
            String(format: "RaiBlocksSwift/temp-%08x", Random.getUInt32())
        
        return try Environment(dataDir: dataDir,
                               tempDir: tempDir)
    }
    
    public static func createTemporary() throws -> Environment {
        let rootDir = FilePath(NSTemporaryDirectory()) +
            String(format: "RaiBlocksSwift/temp-env-%08x", Random.getUInt32())

        try rootDir.createDirectory(intermediates: true)
        
        return try Environment.init(dataDir: rootDir + "data",
                                    tempDir: rootDir + "temp")
    }
}
