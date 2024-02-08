import XCTest
@testable import Meter
import BinaryImage

struct MockSymbolicator {
	typealias SymbolicationHandler = (UInt64, SymbolicationTarget) -> [SymbolInfo]

	var symbolicationHandler: SymbolicationHandler

	init(symbolicationHandler: @escaping SymbolicationHandler) {
		self.symbolicationHandler = symbolicationHandler
    }
}

extension MockSymbolicator: Symbolicator {
    func symbolicate(address: UInt64, in target: SymbolicationTarget) -> [SymbolInfo] {
        return symbolicationHandler(address, target)
    }
}

final class SymbolicationTests: XCTestCase {
	lazy var processImages = BinaryImage.imageMap

    // guard against 64bit addresses
    #if !os(watchOS)
    func testDlfcnSymbolicator() throws {
        // This is a fragile test, because it will only work when running
        // against 12.0 (21A344) on arm. I can think of a way to build a
        // more robust test, but it will take quite a bit of work.
        try XCTSkipUnless(ProcessInfo.processInfo.operatingSystemVersionString == "Version 12.0 (Build 21A344)")

        let symbolicator = DlfcnSymbolicator()
        let target = try XCTUnwrap(SymbolicationTarget(uuid: "17550b77-d255-389a-b779-906af75314b6",
                            loadAddress: 0x19d0c4000,
                            path: "/usr/lib/system/libsystem_kernel.dylib"))

        let infoArray = symbolicator.symbolicate(address: 0x19d0c59b4, in: target)

        XCTAssertEqual(infoArray.count, 1)
        XCTAssertEqual(infoArray[0].symbol, "mach_msg_trap")
        XCTAssertEqual(infoArray[0].offset, 8)
        XCTAssertNil(infoArray[0].lineNumber)
        XCTAssertNil(infoArray[0].file)
    }
	#endif

	func testDlfcnSymbolicatorWithAddressOutsideIntRange() throws {
		let randomImage = try XCTUnwrap(processImages.first)

		let symbolicator = DlfcnSymbolicator()

		// the load address and path are both bogus and will not match the UUID
		let target = try XCTUnwrap(
			SymbolicationTarget(
				uuid: randomImage.key,
				loadAddress: 0x19d0c4000,
				path: "/usr/lib/system/libsystem_kernel.dylib"
			)
		)

		// this will fail, but it should not crash
		let infoArray = symbolicator.symbolicate(address: UInt64(Int.max) + 1, in: target)

		XCTAssertEqual(infoArray.count, 0)
	}

	func testDlfcnSymbolicatorWithFrameAddressOutsideIntRange() throws {
		let symbolicator = DlfcnSymbolicator()

		// this will fail, but it should not crash
		let frame = Frame(address: UInt64(Int.max) + 1, subFrames: nil)

		_ = symbolicator.symbolicate(frame: frame, withOffsetAsLoadAddress: true)
	}

    func testTargetCalculation() throws {
        let uuid = UUID()
        let frame = Frame(binaryUUID: uuid,
                          offsetIntoBinaryTextSegment: 100,
                          binaryName: "binary",
                          address: 105,
                          subFrames: nil)

        let loadTarget = frame.symbolicationTarget(withOffsetAsLoadAddress: true)

        XCTAssertEqual(loadTarget, SymbolicationTarget(uuid: uuid, loadAddress: 100, path: "binary"))

        let offsetTarget = frame.symbolicationTarget(withOffsetAsLoadAddress: false)

        XCTAssertEqual(offsetTarget, SymbolicationTarget(uuid: uuid, loadAddress: 5, path: "binary"))
    }
    
    func testSymbolicateCallStack() throws {
        let uuidB = UUID()
        let frameB = Frame(binaryUUID: uuidB,
                           offsetIntoBinaryTextSegment: 2000,
                           sampleCount: 1,
                           binaryName: "binaryB",
                           address: 2020,
                           subFrames: [])
        let uuidA = UUID()
        let frameA = Frame(binaryUUID: uuidA,
                          offsetIntoBinaryTextSegment: 1000,
                          sampleCount: 1,
                          binaryName: "binaryA",
                          address: 1015, subFrames: [frameB])
        let callStack = CallStack(threadAttributed: true, rootFrames: [frameA])

        let symbolInfoB = SymbolInfo(symbol: "symbolB", offset: 10)
        let symbolInfoA = SymbolInfo(symbol: "symbolA", offset: 10)

		let mockResults = [frameB.address: [symbolInfoB], frameA.address: [symbolInfoA]]

		let mockSymbolicator = MockSymbolicator { addr, _ in
			return mockResults[addr]!
		}

        let symbolicatedStack = mockSymbolicator.symbolicate(callStack: callStack, withOffsetAsLoadAddress: true)

        XCTAssertEqual(symbolicatedStack.threadAttributed, true)
        XCTAssertEqual(symbolicatedStack.rootFrames.count, 1)
        XCTAssertEqual(symbolicatedStack.rootFrames[0].symbolInfo?.count, 1)
        XCTAssertEqual(symbolicatedStack.rootFrames[0].symbolInfo?[0].symbol, "symbolA")
        XCTAssertEqual(symbolicatedStack.rootFrames[0].symbolInfo?[0].offset, 10)

        XCTAssertEqual(symbolicatedStack.rootFrames[0].subFrames?.count, 1)
        XCTAssertEqual(symbolicatedStack.rootFrames[0].subFrames?[0].symbolInfo?[0].symbol, "symbolB")
        XCTAssertEqual(symbolicatedStack.rootFrames[0].subFrames?[0].symbolInfo?[0].offset, 10)
    }

	func testUsingCrashOffsets() {
		let uuidA = UUID()
		let frameA = Frame(binaryUUID: uuidA,
						  offsetIntoBinaryTextSegment: 15,
						  sampleCount: 1,
						  binaryName: "binaryA",
						  address: 1015, subFrames: [])
		let callStack = CallStack(threadAttributed: true, rootFrames: [frameA])
		let tree = CallStackTree(callStacks: [callStack], callStackPerThread: true)

		let offsetCrashMetaData = CrashMetaData(deviceType: "",
												applicationBuildVersion: "",
												applicationVersion: "",
												osVersion: "macOS 13.0 (22A5358e)",
												platformArchitecture: "",
												regionFormat: "",
												isTestFlightApp: nil,
												lowPowerModeEnabled: nil,
												pid: nil,
												virtualMemoryRegionInfo: nil,
												exceptionType: nil,
												terminationReason: nil,
												exceptionCode: nil,
												signal: nil,
												exceptionReason: nil)
		let offsetCrashDiagnotic = CrashDiagnostic(metaData: offsetCrashMetaData, callStackTree: tree)

		let absoluteCrashMetaData = CrashMetaData(deviceType: "",
												  applicationBuildVersion: "",
												  applicationVersion: "",
												  osVersion: "macOS 12.1",
												  platformArchitecture: "",
												  regionFormat: "",
												  isTestFlightApp: nil,
												  lowPowerModeEnabled: nil,
												  pid: nil,
												  virtualMemoryRegionInfo: nil,
												  exceptionType: nil,
												  terminationReason: nil,
												  exceptionCode: nil,
												  signal: nil,
												  exceptionReason: nil)
		let absoluteCrashDiagnotic = CrashDiagnostic(metaData: absoluteCrashMetaData, callStackTree: tree)

		var symbolicationTarget: SymbolicationTarget? = nil

		let mockSymbolicator = MockSymbolicator { _, target in
			symbolicationTarget = target

			return []
		}

		_ = mockSymbolicator.symbolicate(diagnostic: offsetCrashDiagnotic)

		XCTAssertEqual(symbolicationTarget?.loadAddress, 1000)

		_ = mockSymbolicator.symbolicate(diagnostic: absoluteCrashDiagnotic)

		XCTAssertEqual(symbolicationTarget?.loadAddress, 15)
	}

    func testSymbolicatesAllDiagnosticTypes() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "xcode_simulated", withExtension: "json", subdirectory: "Resources"))
        let data = try Data(contentsOf: url, options: [])
        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        let symbolInfo = SymbolInfo(symbol: "symSymbol", offset: 10)

		let mockResults = [UInt64(74565): [symbolInfo]]

		let mockSymbolicator = MockSymbolicator { addr, _ in
			return mockResults[addr]!
		}

        let symPayload = mockSymbolicator.symbolicate(payload: payload)

        XCTAssertEqual(symPayload.crashDiagnostics?[0].callStackTree.callStacks[0].rootFrames[0].symbolInfo, [symbolInfo])
        XCTAssertEqual(symPayload.hangDiagnostics?[0].callStackTree.callStacks[0].rootFrames[0].symbolInfo, [symbolInfo])
        XCTAssertEqual(symPayload.cpuExceptionDiagnostics?[0].callStackTree.callStacks[0].rootFrames[0].symbolInfo, [symbolInfo])
        XCTAssertEqual(symPayload.diskWriteExceptionDiagnostics?[0].callStackTree.callStacks[0].rootFrames[0].symbolInfo, [symbolInfo])
    }
}
