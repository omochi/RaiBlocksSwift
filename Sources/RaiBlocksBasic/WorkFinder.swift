import Foundation

public class WorkFinder {
    public class Task {
        public init(hash: Block.Hash,
                    threshold: UInt64,
                    completeHandler: @escaping (Work) -> Void)
        {
            self.hash = hash
            self.threshold = threshold
            self.completeHandler = completeHandler
        }
        
        public let hash: Block.Hash
        public let threshold: UInt64
        public let completeHandler: (Work) -> Void
        
        public var result: FindResult?
    }
    
    public struct FindResult {
        public var work: Work
        public var score: UInt64
    }
    
    public init(callbackQueue: DispatchQueue,
                workerNum: Int? = nil)
    {
        queue = DispatchQueue.init(label: "WorkFinder.queue")
        self.callbackQueue = callbackQueue
        terminated = false
        
        self.workerNum = workerNum ?? ProcessInfo().activeProcessorCount
        
        pendingTasks = []
    }
    
    public func terminate() {
        queue.sync {
            currentTask = nil
            pendingTasks.removeAll()
            terminated = true
        }
    }
    
    public func find(hash: Block.Hash,
                     threshold: UInt64,
                     completeHandler: @escaping (Work) -> Void)
    {
        let task = Task.init(hash: hash,
                             threshold: threshold,
                             completeHandler: completeHandler)
        queue.async {
            if self.currentTask != nil {
                self.pendingTasks.append(task)
                return
            }
            
            self.startTask(task)
        }
    }
    
    private func startTask(_ task: Task) {
        precondition(currentTask == nil)
        
        currentTask = task

        startWorkers(task: task)
    }
    
    private func startWorkers(task: Task) {
        guard currentTask === task else {
            return
        }
        
        let group = DispatchGroup.init()
        
        for _ in 0..<workerNum {
            group.enter()
            DispatchQueue.global().async {
                let result = WorkFinder._find(task: task)
                self.queue.async {
                    if let bestResult = task.result {
                        guard bestResult.score < result.score else {
                            return
                        }
                    }
                    
                    print(String(format: "bestScore: %016llx", result.score))
                    task.result = result
                }
                group.leave()
            }
        }
        
        group.notify(queue: queue) {
            if task.result!.score >= task.threshold {
                self.complete(task: task)
            } else {
                self.startWorkers(task: task)
            }
        }
    }

    private func complete(task: Task) {
        guard task === currentTask else {
            return
        }

        currentTask = nil
        
        callbackQueue.async {
            let terminated = self.queue.sync { self.terminated }
            if terminated {
                return
            }
            
            task.completeHandler(task.result!.work)
        }
        
        if pendingTasks.count == 0 {
            return
        }
        
        let nextTask = pendingTasks[0]
        pendingTasks.remove(at: 0)
        
        startTask(nextTask)
    }
    
    private static func _find(task: Task) -> FindResult {
        var bestResult: FindResult?
        
        for _ in 0..<10000 {
            let work = Work.generateRandom()
            let score = work.score(for: task.hash)
            if let bestResult = bestResult {
                guard bestResult.score < score else {
                    continue
                }
            }
            
            bestResult = FindResult(work: work, score: score)
        }
        
        return bestResult!
    }
    
    private let queue: DispatchQueue
    private let callbackQueue: DispatchQueue
    private let workerNum: Int
    private var terminated: Bool
    
    private var currentTask: Task?
    private var pendingTasks: [Task]
}

