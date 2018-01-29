import Foundation
import RaiBlocksSocket

extension IPv6.EndPoint : DataWritable {
    public func write(to writer: DataWriter) {
        var addr = address.addr
        let addrSize = 16
        UnsafeMutablePointer<in6_addr>(&addr).withMemoryRebound(to: UInt8.self, capacity: addrSize) { (p) in
            writer.write(p, size: addrSize)
        }
        writer.write(UInt16(self.port), byteOrder: .little)
    }
}
