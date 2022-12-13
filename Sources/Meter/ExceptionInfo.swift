import Foundation
import BinaryImage

public struct ExceptionInfo: Codable {
    public let name: String
    public let reason: String
    public let backtrace: [Frame]

    public init(name: String, reason: String, backtrace: [Frame]) {
        self.name = name
        self.reason = reason
        self.backtrace = backtrace
    }

    public init(exception: NSException) {
        self.name = exception.name.rawValue
        self.reason = exception.reason ?? ""
        self.backtrace = [exception.frameRepresentation]
    }

    public func write(to url: URL) throws {
        let data = try JSONEncoder().encode(self)

        try data.write(to: url)
    }

    public func matchesCrashDiagnostic(_ diagnostic: CrashDiagnostic) -> Bool {
        // ok, yes, this is insufficient
        return true
    }
}

extension NSException {
    public var frameRepresentation: Frame {
        let addresses = callStackReturnAddresses.map({ $0.intValue })

        var binaryMap = [Int : Binary]()

        var frame: Frame? = nil

        // both creating the DynamicLibraryInfo and calling makeBinary are
        // expensive. Use a simple cache to avoid one of those operations.

        for addr in addresses.reversed() {
            let info = DynamicLibraryInfo(address: addr) ?? DynamicLibraryInfo()

            let binary = binaryMap[info.loadAddress] ?? info.makeBinary()
			let loadAddress = binary?.loadAddress ?? info.loadAddress

            if binary != nil && info.loadAddress > 0 {
                binaryMap[info.loadAddress] = binary
            }

            let subFrames = [frame].compactMap({ $0 })

			// have to account for the change in recent platforms to make this an actual offset
			let offset: Int

			if #available(macOS 13, iOS 16, *) {
				offset = addr - loadAddress
			} else {
				offset = loadAddress
			}

            frame = Frame(binaryUUID: binary?.uuid,
						  offsetIntoBinaryTextSegment: offset,
                          binaryName: binary?.name,
                          address: UInt64(addr),
                          subFrames: subFrames,
                          symbolInfo: [info.symbolInfo])
        }

        return frame ?? Frame(address: 0, subFrames: nil)
    }
}
