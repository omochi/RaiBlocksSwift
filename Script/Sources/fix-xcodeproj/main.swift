import Foundation
import PathKit
import xcproj

let repoDir = Path(FileManager.default.currentDirectoryPath).parent()
let xcodeProjPath = repoDir + "RaiBlocksSwift.xcodeproj"
let xcodeProj = try XcodeProj(path: xcodeProjPath)
let target: PBXTarget = xcodeProj.pbxproj.objects.getTarget(reference: "SQLite.swift::SQLiteObjc")!
let configList = xcodeProj.pbxproj.objects.configurationLists[target.buildConfigurationList!]!
for config in configList.buildConfigurations {
    let buildConfig = xcodeProj.pbxproj.objects.buildConfigurations[config]!
    buildConfig.buildSettings["CLANG_ENABLE_MODULES"] = "YES"
}
try xcodeProj.write(path: xcodeProjPath)

