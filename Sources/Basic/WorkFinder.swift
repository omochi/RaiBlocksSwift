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
            self.bestScore = 0
        }
        
        public let hash: Block.Hash
        public let threshold: UInt64
        public let completeHandler: (Work) -> Void
        
        public var bestScore: UInt64
    }
    
    public class Worker {
        public init(index: Int,
                    task: Task,
                    bestScoreHandler: @escaping (UInt64) -> Void,
                    completeHandler: @escaping (Work) -> Void)
        {
            self.queue = DispatchQueue.init(label: "WorkFinder.Worker[\(index)]")
            self.task = task
            self.bestScoreHandler = bestScoreHandler
            self.completeHandler = completeHandler
            self.terminated = false
            self.bestScore = 0
            queue.async {
                self.run()
            }
        }
        
        public func terminate() {
            queue.sync {
                terminated = true
            }
        }
        
        private func run() {
            if terminated {
                return
            }
            
            for _ in 0..<1000 {
                let work = Work.generateRandom()
                let score = task.hash.score(of: work)
                if bestScore < score {
                    bestScore = score
                    bestScoreHandler(score)
                }
                if score >= task.threshold {
                    completeHandler(work)
                    return
                }
            }
            
            queue.async { self.run() }
        }
        
        private let queue: DispatchQueue
        private let task: Task
        private let bestScoreHandler: (UInt64) -> Void
        private let completeHandler: (Work) -> Void
        private var terminated: Bool
        
        private var bestScore: UInt64
    }
    
    public init(callbackQueue: DispatchQueue,
                workerNum: Int? = nil)
    {
        queue = DispatchQueue.init(label: "WorkFinder.queue")
        self.callbackQueue = callbackQueue
        terminated = false
        
        self.workerNum = workerNum ?? ProcessInfo().activeProcessorCount
        workers = []
        
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
        
        for index in 0..<workerNum {
            let worker = Worker.init(index: index, task: task,
                                     bestScoreHandler: { score in
                                        self.queue.async {
                                            self.updateBestScore(task: task, score: score)
                                        }
            },
                                     completeHandler: { work in
                                        self.queue.async {
                                            self.complete(task: task, work: work)
                                        }
            })
            workers.append(worker)
        }
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
            worker.terminate()
        }
        workers.removeAll()
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
    private let workerNum: Int
    private var terminated: Bool
    
    private var currentTask: Task?
    private var workers: [Worker]
    private var pendingTasks: [Task]
}

