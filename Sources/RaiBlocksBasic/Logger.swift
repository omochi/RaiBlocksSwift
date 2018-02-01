import Foundation

public class Logger {
    public enum Level : Int, CustomStringConvertible {
        case trace = 0
        case debug
        case info
        case warn
        case error
        
        public var description: String {
            switch self {
            case .trace: return "TRACE"
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warn: return "WARN"
            case .error: return "ERROR"
            }
        }
    }
    
    public class Config {
        public var level: Level
        
        public init(level: Level = .info) {
            self.level = level
        }
    }
    
    public init(config: Config, tag: String? = nil) {
        self.config = config
        self.tag = tag
    }
    
    public var config: Config
    public var tag: String?

    public func trace(_ message: String) {
        log(level: .trace, message)
    }
    
    public func debug(_ message: String) {
        log(level: .debug, message)
    }
    
    public func info(_ message: String) {
        log(level: .info, message)
    }
    
    public func warn(_ message: String) {
        log(level: .warn, message)
    }
    
    public func error(_ message: String) {
        log(level: .error, message)
    }
    
    public func log(level: Level, _ message: String) {
        guard level.rawValue >= config.level.rawValue else {
            return
        }
        
        var tags: [String] = []
        tags.append(level.description)
        if let tag = self.tag {
            tags.append(tag)
        }
        log(tags: tags, message)
    }
    
    private func log(tags: [String], _ message: String) {
        var strs = tags.map { "[\($0)]" }
        strs.append(message)
        let line = strs.joined(separator: " ")
        Swift.print(line)
    }
    
}

