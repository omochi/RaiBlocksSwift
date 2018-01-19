import Foundation

public class WorkFinder {
    public class Task {
        public var hash: Block.Hash
        public var threshold: UInt64
        public var completeHandler: (Work) -> Void
        public var bestScore: UInt64

        public init(hash: Block.Hash,
                    threshold: UInt64,
                    completeHandler: @escaping (Work) -> Void)
        {
            self.hash = hash
            self.threshold = threshold
            self.completeHandler = completeHandler
            self.bestScore = 0
        }
        
        public convenience init(task: Task) {
            self.init(hash: task.hash,
                      threshold: task.threshold,
                      completeHandler: task.completeHandler)
        }
    }
    
    public class WorkerInfo {
        public let task: Task
        public var bestScore: UInt64
        
        public init(task: Task) {
            self.task = task
            self.bestScore = 0
        }
    }
    
    public init(callbackQueue: DispatchQueue,
                workerNum: Int? = nil)
    {
        queue = DispatchQueue.init(label: "WorkFinder.queue")
        self.callbackQueue = callbackQueue
        terminated = false
        
        let workerNum = workerNum ?? ProcessInfo().activeProcessorCount
        var workers: [Worker<WorkerInfo>] = []
        for i in 0..<workerNum {
            workers.append(Worker.init(name: "WorkFinder.Worker[\(i)]"))
        }
        self.workers = workers
        
        pendingTasks = []
    }
    
    public func terminate() {
        queue.sync {
            currentTask = nil
            pendingTasks.removeAll()
            self.terminated = true
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
        
        workers.forEach { worker in
            let info = WorkerInfo.init(task: task)
            worker.start(info: info) {
                self.process(info: $0)
            }
        }
    }
    
    private func process(info: WorkerInfo) -> Bool {
        let task = info.task
        for _ in 0..<1000 {
            let work = Work.generateRandom()
            let score = task.hash.score(of: work)
            if info.bestScore < score {
                info.bestScore = score
                queue.async {
                    self.updateBestScore(task: task, score: score)
                }
            }
            if score >= task.threshold {
                queue.async {
                    self.complete(task: task, work: work)
                }
                return false
            }
        }
        return true
    }
    
    private func updateBestScore(task: Task, score: UInt64) {
        guard task === currentTask else {
            return
        }
        
        if task.bestScore < score {
            task.bestScore = score
//            print(String(format: "bestScore: %016llx", score))
        }
    }
    
    private func complete(task: Task, work: Work) {
        guard task === currentTask else {
            return
        }
        
        workers.forEach { worker in
            worker.pause()
        }
        
        let task = currentTask!
        currentTask = nil
        
        callbackQueue.async {
            let terminated = self.queue.sync { self.terminated }
            if terminated {
                return
            }
            
            task.completeHandler(work)
        }
        
        if pendingTasks.count == 0 {
            return
        }
        
        let nextTask = pendingTasks[0]
        pendingTasks.remove(at: 0)
        
        startTask(nextTask)
    }
    
    private let queue: DispatchQueue
    private let callbackQueue: DispatchQueue
    private var terminated: Bool
    
    private var currentTask: Task?
    private var workers: [Worker<WorkerInfo>]
    private var pendingTasks: [Task]
}

