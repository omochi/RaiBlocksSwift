import Foundation
import RaiBlocksBasic
import RaiBlocksNode

func main() {
    let loggerConfig = Logger.Config(level: .debug)
    let mainQueue: DispatchQueue = .main
    let logger: Logger = Logger(config: loggerConfig, tag: "main")
    var node: Node!
    
    func boot() {
        do {
            let fileSystem = try FileSystem.createDefault()
            let network = Network.main
            let storage = try Storage(fileSystem: fileSystem,
                                      network: network)
            let config = Node.Config(loggerConfig: loggerConfig,
                                     fileSystem: fileSystem,
                                     network: network,
                                     storage: storage)
            let queue = DispatchQueue.init(label: "node-queue")
            node = Node(queue: queue,
                        config: config)
            
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
