import XCTest
@testable import Meter
import BinaryImage

struct MockSymbolicator {
    var mockResults: [Int: [SymbolInfo]]

    init() {
        self.mockResults = [:]
    }
}

extension MockSymbolicator: Symbolicator {
    func symbolicate(address: Int, in target: SymbolicationTarget) -> [SymbolInfo] {
        return mockResults[address] ?? []
    }
}

final class SymbolicationTests: XCTestCase {
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

        var mockSymbolicator = MockSymbolicator()

        mockSymbolicator.mockResults[frameB.address] = [symbolInfoB]
        mockSymbolicator.mockResults[frameA.address] = [symbolInfoA]

        let symbolicatedStack = mockSymbolicator.symbolicate(callStack: callStack)

        XCTAssertEqual(symbolicatedStack.threadAttributed, true)
        XCTAssertEqual(symbolicatedStack.rootFrames.count, 1)
        XCTAssertEqual(symbolicatedStack.rootFrames[0].symbolInfo?.count, 1)
        XCTAssertEqual(symbolicatedStack.rootFrames[0].symbolInfo?[0].symbol, "symbolA")
        XCTAssertEqual(symbolicatedStack.rootFrames[0].symbolInfo?[0].offset, 10)

        XCTAssertEqual(symbolicatedStack.rootFrames[0].subFrames?.count, 1)
        XCTAssertEqual(symbolicatedStack.rootFrames[0].subFrames?[0].symbolInfo?[0].symbol, "symbolB")
        XCTAssertEqual(symbolicatedStack.rootFrames[0].subFrames?[0].symbolInfo?[0].offset, 10)
    }
}
