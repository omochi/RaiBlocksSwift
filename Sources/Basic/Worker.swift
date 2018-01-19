import Foundation

public class Worker<T: AnyObject> {    
    public init(name: String)
    {
        self.name = name
        self.queue = DispatchQueue.init(label: "Worker(\(name)).queue")
        self._paused = true
    }
    
    public let name: String
    
    public func start(info: T, process: @escaping (T) -> Bool) {
        queue.async {
            precondition(self._paused)
            
            self.process = process
            
            self._paused = false
            self.info = info
            self.run(info: info)
        }
    }
    
    public func pause() {
        queue.sync {
            self._pause()
        }
    }
    
    private func run(info: T) {
        if self.info !== info {
            return
        }
        
        let cont = process!(info)
        if !cont {
            _pause()
            return
        }
        
        queue.async {
            self.run(info: info)
        }
    }
    
    private func _pause() {
        _paused = true
        info = nil
    }
    
    private let queue: DispatchQueue
    private var _paused: Bool
    private var info: T?
    private var process: ((T) -> Bool)?
}
