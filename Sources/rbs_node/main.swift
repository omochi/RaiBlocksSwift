import Foundation
import RaiBlocksBasic
import RaiBlocksNode

func main() {
    let mainQueue: DispatchQueue = .main
    let logger: Logger = Logger.init(config: Logger.Config(level: .trace))
    var node: Node!
    
    func boot() {
        do {
            let environment = try Environment.createDefault()
            let config = Node.Config()
            let queue = DispatchQueue.init(label: "node-queue")
            node = Node(environment: environment,
                        logger: logger,
                        config: config,
                        queue: queue)
            
            try node!.start()
            
            mainQueue.async {
                loop()
            }
        } catch let error {
            fatal(String(describing: error))
        }
    }
    
    func loop() {
        let x = getchar()
        logger.trace("loop.getchar: \(x)")
        
        mainQueue.async {
            loop()
        }
    }
    
    func fatal(_ message: String) -> Never {
        logger.error(message)
        Darwin.exit(EXIT_FAILURE)
    }
    
    mainQueue.async {
        boot()
    }
    
    dispatchMain()
}

main()
