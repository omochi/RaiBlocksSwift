import Foundation
import CRandom
import ED25519Donna

public struct ED25519 {
    public struct SecretKey {
        public init(data: Data) {
            precondition(data.count == SecretKey.size)
            
            self._data = data
        }
        
        public func asData() -> Data {
            return _data
        }
        
        public static let size: Int = 32
        
        private let _data: Data
    }
    
    public struct PublicKey {
        public init(data: Data) {
            precondition(data.count == PublicKey.size)
            
            self._data = data
        }
        
        public func asData() -> Data {
            return _data
        }
        
        public static let size: Int = 32
        
        private let _data: Data
    }
}

extension ED25519.SecretKey {
    public static func generate() -> ED25519.SecretKey {
        var data = Data.init(count: ED25519.SecretKey.size)
        data.withUnsafeMutableBytes { p in
            crandom_buf(p, data.count)
        }
        return ED25519.SecretKey.init(data: data)
    }
    
    public func generatePublicKey() -> ED25519.PublicKey {
        let secData = asData()
        var pubData = Data.init(count: ED25519.PublicKey.size)
        
        secData.withUnsafeBytes { (sec: UnsafePointer<UInt8>) in
            pubData.withUnsafeMutableBytes { (pub: UnsafeMutablePointer<UInt8>) in
                ed25519_publickey(sec, pub)
            }
        }
        
        return ED25519.PublicKey.init(data: pubData)
    }
}

extension ED25519.PublicKey {
    public func asAccountAddress() -> Account.Address {
        return Account.Address.init(data: asData())
    }
}

