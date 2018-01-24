//
//  FilePath.swift
//  RaiBlocksBasic
//
//  Created by omochimetaru on 2018/01/24.
//

import Foundation

public struct FilePath : CustomStringConvertible {
    public init(_ string: String) {
        self.url = URL.init(fileURLWithPath: string)
    }
    
    public init(url: URL) {
        precondition(url.isFileURL)
        self.url = url
    }
    
    public var description: String {
        return url.relativePath
    }
    
    public var parent: FilePath {
        return FilePath(url: url.deletingLastPathComponent())
    }
    
    public func createDirectory(intermediates: Bool) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url, withIntermediateDirectories: intermediates)
    }

    public static func +(a: FilePath, b: FilePath) -> FilePath {
        return a + b.description
    }
    
    public static func +(a: FilePath, b: String) -> FilePath {
        return FilePath(url: a.url.appendingPathComponent(b))
    }
    
    private var url: URL
}
