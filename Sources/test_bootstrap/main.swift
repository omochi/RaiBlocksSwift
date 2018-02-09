import Foundation
import RaiBlocksBasic
import RaiBlocksNode

let loggerConfig = Logger.Config(level: .debug)
let fileSystem = try FileSystem.createDefault()
let network = Network.main
let storage = try Storage(fileSystem: fileSystem,
                          network: network)






dispatchMain()
