import Foundation

public class Logger {
    public init() {}
    
    public func info(_ message: String) {
        print("[INFO] \(message)")
    }
    
    public func error(_ message: String) {
        print("[ERROR] \(message)")
    }
}

public class TaggedLogger {
    public init(tag: String,
                logger: Logger)
    {
        self.tag = tag
        self.logger = logger
    }
    
    public func info(_ message: String) {
        logger.info("[\(tag)] \(message)")
    }
    
    public func error(_ message: String) {
        logger.error("[\(tag)] \(message)")
    }
    
    public let tag: String
    public let logger: Logger
}
