import Foundation
import BinaryImage

public struct SymbolInfo: Codable, Hashable {
    public var offset: Int?
    public var symbol: String
    public var demangledSymbol: String?
    public var file: String?
    public var lineNumber: Int?

    public init(symbol: String, demangledSymbol: String? = nil, offset: Int? = nil, file: String? = nil, lineNumber: Int? = nil) {
        self.symbol = symbol
        self.demangledSymbol = demangledSymbol
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

public struct SymbolicationTarget: Hashable {
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

public extension Frame {
    func symbolicationTarget(withOffsetAsLoadAddress: Bool) -> SymbolicationTarget? {
        let binary = binary(withOffsetAsLoadAddress: withOffsetAsLoadAddress)

        return binary.map({ SymbolicationTarget(uuid: $0.uuid, loadAddress: $0.loadAddress, path: $0.name) })
    }
}

public extension Symbolicator {
    func symbolicate(frame: Frame, withOffsetAsLoadAddress: Bool) -> Frame {
        let subframes = frame.subFrames ?? []
        let symSubframes = subframes.map({ symbolicate(frame: $0, withOffsetAsLoadAddress: withOffsetAsLoadAddress) })

		let addr = Int(frame.address)
        let target = frame.symbolicationTarget(withOffsetAsLoadAddress: withOffsetAsLoadAddress)
        let info = target.map({ symbolicate(address: addr, in: $0) }) ?? []

        return Frame(frame: frame, symbolInfo: info, subFrames: symSubframes)
    }

    func symbolicate(callStack: CallStack, withOffsetAsLoadAddress: Bool) -> CallStack {
        let symFrames = callStack.rootFrames.map({ symbolicate(frame: $0, withOffsetAsLoadAddress: withOffsetAsLoadAddress) })
        let attributed = callStack.threadAttributed ?? false

        return CallStack(threadAttributed: attributed, rootFrames: symFrames)
    }

    func symbolicate(tree: CallStackTree, withOffsetAsLoadAddress: Bool) -> CallStackTree {
        let stacks = tree.callStacks.map({ symbolicate(callStack: $0, withOffsetAsLoadAddress: withOffsetAsLoadAddress) })

        return CallStackTree(callStacks: stacks,
                             callStackPerThread: tree.callStackPerThread)
    }

    func symbolicate(diagnostic: CrashDiagnostic) -> CrashDiagnostic {
        let metadata = CrashMetaData(diagnostic: diagnostic)

		let useOffsets = diagnostic.usesOffsetAsLoadAddress
        let symTree = symbolicate(tree: diagnostic.callStackTree, withOffsetAsLoadAddress: useOffsets)

        return CrashDiagnostic(metaData: metadata, callStackTree: symTree)
    }

    func symbolicate(diagnostic: HangDiagnostic) -> HangDiagnostic {
        let metadata = HangMetaData(diagnostic: diagnostic)

        let symTree = symbolicate(tree: diagnostic.callStackTree, withOffsetAsLoadAddress: false)

        return HangDiagnostic(metaData: metadata, callStackTree: symTree)
    }

    func symbolicate(diagnostic: DiskWriteExceptionDiagnostic) -> DiskWriteExceptionDiagnostic {
        let metadata = DiskWriteExceptionMetaData(diagnostic: diagnostic)

        let symTree = symbolicate(tree: diagnostic.callStackTree, withOffsetAsLoadAddress: false)

        return DiskWriteExceptionDiagnostic(metaData: metadata, callStackTree: symTree)
    }

    func symbolicate(diagnostic: CPUExceptionDiagnostic) -> CPUExceptionDiagnostic {
        let metadata = CPUExceptionMetaData(diagnostic: diagnostic)

        let symTree = symbolicate(tree: diagnostic.callStackTree, withOffsetAsLoadAddress: false)

        return CPUExceptionDiagnostic(metaData: metadata, callStackTree: symTree)
    }

    func symbolicate(payload: DiagnosticPayload) -> DiagnosticPayload {
        let symCrashDiagnostics = payload.crashDiagnostics?.map({ symbolicate(diagnostic: $0) })
        let symHangDiagnostics = payload.hangDiagnostics?.map({ symbolicate(diagnostic: $0) })
        let symCPUDiagnostics = payload.cpuExceptionDiagnostics?.map({ symbolicate(diagnostic: $0) })
        let diskWriteDiagnostics = payload.diskWriteExceptionDiagnostics?.map({ symbolicate(diagnostic: $0) })

        return DiagnosticPayload(timeStampBegin: payload.timeStampBegin,
                                 timeStampEnd: payload.timeStampEnd,
                                 crashDiagnostics: symCrashDiagnostics,
                                 hangDiagnostics: symHangDiagnostics,
                                 cpuExceptionDiagnostics: symCPUDiagnostics,
                                 diskWriteExceptionDiagnostics: diskWriteDiagnostics)
    }
}
