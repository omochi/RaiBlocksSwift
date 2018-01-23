//
//  PosixError.swift
//  Basic
//
//  Created by omochimetaru on 2018/01/22.
//

import Foundation

public struct PosixError : Swift.Error, CustomStringConvertible {
    public init(errno: Int32, message: String) {
        self.errno = errno
        self.message = message
    }
    
    public var errno: Int32
    public var message: String

    public var errStr: String {
        return String.init(cString: strerror(errno))
    }
    
    public var description: String {
        return "\(message): \(errStr)(\(errno))"
    }
}
