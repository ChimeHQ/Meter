import Foundation

public struct MetricKitUnavailableData {
    public var pid = 0
    public var executablePath: String? = nil
    public var bundleIdentifier: String? = nil
    public var uid = 0

    public init() {
    }
}

extension MetaDataProtocol {
    var renderedArchitecture: String {
        switch platformArchitecture {
        case "arm64":
            return "ARM-64"
        default:
            return platformArchitecture
        }
    }
}

public extension CrashDiagnosticProtocol {
    func renderCrash(unavailableData: MetricKitUnavailableData = .init()) -> String {
        let images = self.callStackTree.binaryImages

        let firstImageName = images.first?.name ?? "<unknown>"
        let pid = unavailableData.pid
        let identifier = unavailableData.bundleIdentifier ?? firstImageName
        let path = unavailableData.executablePath ?? "<unknown>"

        var output: String = ""

        output += "Process:               \(firstImageName) [\(pid)]\n"
        output += "Path:                  \(path)\n"
        output += "Identifier:            \(identifier)\n"
        output += "Version:               \(metaData.applicationBuildVersion)\n"
        output += "Code Type:             \(metaData.renderedArchitecture) (Native)\n"
        output += "Parent Process:        ??? [0]\n"
        output += "Responsible:           \(firstImageName) [\(pid)]\n"
        output += "User ID:               \(unavailableData.uid)\n\n"

        return output
    }
}
