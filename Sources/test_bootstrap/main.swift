import Foundation
import RaiBlocksBasic
import RaiBlocksNode


let loggerConfig = Logger.Config(level: .debug)
let fileSystem = try FileSystem.createDefault()
let network = Network.main
let storage = try Storage(fileSystem: fileSystem,
                          network: network)

let queue = DispatchQueue(label: "bootstrap")
let bootstrap = BootstrapDriver(queue: queue,
                                network: network,
                                hostname: "rai.raiblocks.net",
                                errorHandler: { error in
                                    print("\(error)") }
)

func loop() {
    let x = getchar()
    print(x)
    
    DispatchQueue.main.async {
        loop()
    }
}

loop()

dispatchMain()


