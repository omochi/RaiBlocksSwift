import Foundation
import RaiBlocksSocket

extension IPv6.Address : DataWritable {
    public func write(to writer: DataWriter) {
        var addr = self.addr
        let addrSize = 16
        UnsafeMutablePointer<in6_addr>(&addr).withMemoryRebound(to: UInt8.self, capacity: addrSize) { (p) in
            writer.write(p, size: addrSize)
        }
    }
}

extension IPv6.Address : DataReadable {
    public init(from reader: DataReader) throws {
        let data = try reader.read(Data.self, size: 16)
        let addr = data.withUnsafeBytes { (p: UnsafePointer<in6_addr>) in
            p.pointee
        }
        self.init(addr: addr)
    }
}

extension IPv6.EndPoint : DataWritable {
    public func write(to writer: DataWriter) {
        writer.write(address)
        writer.write(UInt16(self.port), byteOrder: .little)
    }
}

extension IPv6.EndPoint : DataReadable {
    public init(from reader: DataReader) throws {
        self.address = try reader.read(IPv6.Address.self)
        self.port = Int(try reader.read(UInt16.self, from: .little))
    }
}
