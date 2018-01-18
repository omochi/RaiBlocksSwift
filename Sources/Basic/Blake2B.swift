import Foundation
import Blake2

public struct Blake2B {
    public init(outputSize: Int) {
        var state: blake2b_state = .init()
        let ok = blake2b_init(&state, outputSize)
        assert(ok == 0, "blake2b_init failed: outputSize=\(outputSize)")
        self.state = state
    }
    
    public mutating func update(data: Data) {
        let ok = data.withUnsafeBytes { p in
            blake2b_update(&state, p, data.count)
        }
        assert(ok == 0, "blake2b_update failed: size=\(data.count)")
    }
    
    public mutating func finalize() -> Data {
        var ret = Data.init(count: Int(state.outlen))
        let ok = ret.withUnsafeMutableBytes { p in
            blake2b_final(&state, p, ret.count)
        }
        assert(ok == 0, "blake2b_final failed: size=\(ret.count)")
        return ret
    }
    
    public static func compute(data: Data, outputSize: Int) -> Data {
        var blake = Blake2B.init(outputSize: outputSize)
        blake.update(data: data)
        return blake.finalize()
    }
    
    private var state: blake2b_state
}
