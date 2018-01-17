import Foundation

extension Account.Address : CustomStringConvertible {
    public var description: String {
        return asData().toHex()
    }
}
