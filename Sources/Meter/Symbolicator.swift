import Foundation
import BinaryImage
import MetricKit

public struct SymbolInfo: Codable, Hashable {
    public var offset: Int?
    public var symbol: String
    public var file: String?
    public var lineNumber: Int?

    public init(symbol: String, offset: Int? = nil, file: String? = nil, lineNumber: Int? = nil) {
        self.symbol = symbol
        self.offset = offset
        self.file = file
        self.lineNumber = lineNumber
    }
}

extension SymbolInfo: CustomDebugStringConvertible {
    public var debugDescription: String {
        var str = "<Symbol: \(symbol)"

        if let offset = offset {
            str += " + \(offset)"
        }

        if let file = file {
            str += " \(file)"
        }

        if let line = lineNumber {
            str += ":\(line)"
        }

        return str + ">"
    }
}

public struct SymbolicationTarget {
    public var uuid: UUID
    public var loadAddress: Int
    public var path: String?

    public init(uuid: UUID, loadAddress: Int, path: String? = nil) {
        self.uuid = uuid
        self.loadAddress = loadAddress
        self.path = path
    }

    public init?(uuid: String, loadAddress: Int, path: String? = nil) {
        guard let value = UUID(uuidString: uuid) else { return nil }

        self.uuid = value
        self.loadAddress = loadAddress
        self.path = path
    }
}

public protocol Symbolicator {
    func symbolicate(address: Int, in target: SymbolicationTarget) -> [SymbolInfo]
}

public extension Symbolicator {
    func symbolicate(frame: Frame) -> Frame {
        let subframes = frame.subFrames ?? []
        let symSubframes = subframes.map({ symbolicate(frame: $0) })

        let addr = frame.address
        let info = frame.symbolicationTarget.map({ symbolicate(address: addr, in: $0) }) ?? []

        return Frame(frame: frame, symbolInfo: info, symbolicatedSubFrames: symSubframes)
    }

    func symbolicate(callStack: CallStack) -> CallStack {
        let symFrames = callStack.rootFrames.map({ symbolicate(frame: $0) })
        let attributed = callStack.threadAttributed

        return CallStack(threadAttributed: attributed, rootFrames: symFrames)
    }

    func symbolicate(tree: CallStackTreeProtocol) -> CallStackTree {
        let stacks = tree.callStacks.map({ symbolicate(callStack: $0) })

        return CallStackTree(callStacks: stacks,
                             callStackPerThread: tree.callStackPerThread)
    }

    func symbolicate(diagnostic: CrashDiagnosticProtocol) -> CrashDiagnostic {
        let metadata = CrashMetaData(diagnostic: diagnostic)

        let symTree = symbolicate(tree: diagnostic.callStackTree)

        return CrashDiagnostic(metaData: metadata, callStackTree: symTree)
    }

    func symbolicate(payload: DiagnosticPayloadProtocol) -> DiagnosticPayload {
        let symDiagnostics = payload.crashDiagnostics?.map({ symbolicate(diagnostic: $0) })

        return DiagnosticPayload(timeStampBegin: payload.timeStampBegin,
                                 timeStampEnd: payload.timeStampEnd,
                                 crashDiagnostics: symDiagnostics)
    }
}

extension Symbolicator {
    
}

extension Symbolicator {
    func lookupPath(for binary: Binary) -> String? {
        guard let name = binary.name else {
            return nil
        }

        let manager = FileManager.default

        switch name {
        case "dyld", "libdyld.dylib":
            return "/usr/lib/" + name
        case "libsystem_kernel.dylib", "libsystem_pthread.dylib", "libdispatch.dylib":
            return "/usr/lib/system/" + name
        default:
            break
        }

        // /usr/lib/?
        let usrLibPath = "/usr/lib/" + name
        if manager.isReadableFile(atPath: usrLibPath) {
            return usrLibPath
        }

        let usrLibSystem = "/usr/lib/system/" + name
        if manager.isReadableFile(atPath: usrLibSystem) {
            return usrLibSystem
        }

        return nil
    }
}
