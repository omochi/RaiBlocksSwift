extension Optional {
    public func unwrap(or errorMessage: @autoclosure () -> String) throws -> Wrapped {
        guard let value = self else {
            throw GenericError(message: errorMessage())
        }
        return value
    }
}
