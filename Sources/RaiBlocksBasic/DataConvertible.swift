import Foundation
import SQLite

public protocol DataConvertible {
    func asData() -> Data
}

extension DataConvertible {
    public func asSQLite() -> SQLite.Blob {
        return asData().asSQLite()
    }
}
