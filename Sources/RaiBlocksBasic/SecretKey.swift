import Foundation
import RaiBlocksCRandom
import ED25519Donna

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

extension SecretKey {
    public static func generate() -> SecretKey {
        var data = Data.init(count: SecretKey.size)
        data.withUnsafeMutableBytes { p in
            crandom_buf(p, data.count)
        }
        return SecretKey.init(data: data)
    }
    
    public func generateAddress() -> Account.Address {
        let secData = asData()
        var pubData = Data.init(count: Account.Address.size)
        
        secData.withUnsafeBytes { (sec: UnsafePointer<UInt8>) in
            pubData.withUnsafeMutableBytes { (pub: UnsafeMutablePointer<UInt8>) in
                ed25519_publickey(sec, pub)
            }
        }
        
        return Account.Address.init(data: pubData)
    }
    
    public func sign(message: Data, address: Account.Address) -> Signature {
        let secData = asData()
        let pubData = address.asData()
        var sigData = Data.init(count: Signature.size)
        
        message.withUnsafeBytes { msg in
            secData.withUnsafeBytes { sec in
                pubData.withUnsafeBytes { pub in
                    sigData.withUnsafeMutableBytes { sig in
                        ed25519_sign(msg, message.count, sec, pub, sig)
                    }
                }
            }
        }
        
        return Signature.init(data: sigData)
    }
}
