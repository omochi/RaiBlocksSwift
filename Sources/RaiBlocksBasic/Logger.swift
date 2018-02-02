import Foundation

public class Logger {
    public enum Level : Int, CustomStringConvertible, Comparable {
        case trace = 0
        case debug
        case info
        case warn
        case error
        case silent
        
        public var description: String {
            switch self {
            case .trace: return "TRACE"
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warn: return "WARN"
            case .error: return "ERROR"
            case .silent: return "SILENT"
            }
        }
    }

    public class Config {
        public var level: Level
        
        public var tagLevel: [String: Level]
        
        public init(level: Level = .info) {
            self.level = level
            self.tagLevel = [:]
        }
        
        public func level(for tag: String) -> Level {
            if let level = tagLevel[tag] {
                return level
            }
            return self.level
        }
    }
    
    public init(config: Config, tag: String) {
        self.config = config
        self.tag = tag
        
        dateFormatter = DateFormatter.init()
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
    }
    
    public var config: Config
    public var tag: String

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
        guard config.level(for: tag) <= level else {
            return
        }
        
        let timeTag = self.timeTag()
        
        var tags: [String] = []        
        tags.append(timeTag)
        tags.append(level.description)
        tags.append(tag)
        log(tags: tags, message)
    }
    
    private func timeTag() -> String {
        let now = Date.init()
        return dateFormatter.string(from: now)
    }
    
    private func log(tags: [String], _ message: String) {
        var strs = tags.map { "[\($0)]" }
        strs.append(message)
        let line = strs.joined(separator: " ")
        Swift.print(line)
    }
    
    private let dateFormatter: DateFormatter
}


public func ==(a: Logger.Level, b: Logger.Level) -> Bool {
    return a.rawValue == b.rawValue
}

public func <(a: Logger.Level, b: Logger.Level) -> Bool {
    return a.rawValue < b.rawValue
}

