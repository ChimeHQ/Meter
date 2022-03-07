import XCTest
@testable import Meter

class DiagnosticTests: XCTestCase {
    func testReadingSimulatedCrashDiagnosticsData() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "xcode_simulated", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        XCTAssertEqual(payload.timeStampBegin, Date(timeIntervalSince1970: 1602358524))
        XCTAssertEqual(payload.timeStampEnd, Date(timeIntervalSince1970: 1602358524))

        XCTAssertEqual(payload.crashDiagnostics?.count, 1)
        let crashDiagnostic = try XCTUnwrap(payload.crashDiagnostics?[0])

        XCTAssertEqual(crashDiagnostic.metaData.applicationBuildVersion, "1")
        XCTAssertEqual(crashDiagnostic.metaData.osVersion, "iPhone OS 14.0.1 (18A393)")
        if #available(iOS 14.0, macOS 12.0, *) {
            XCTAssertEqual(crashDiagnostic.metaData.platformArchitecture, "arm64")
        }
        XCTAssertEqual(crashDiagnostic.metaData.regionFormat, "CA")
        XCTAssertEqual(crashDiagnostic.virtualMemoryRegionInfo?.hasPrefix("0 is not in any region"), true)
        XCTAssertEqual(crashDiagnostic.applicationVersion, "1.0")
        XCTAssertEqual(crashDiagnostic.terminationReason, "Namespace SIGNAL, Code 0xb")
        XCTAssertEqual(crashDiagnostic.signal, 11)
        XCTAssertEqual(crashDiagnostic.exceptionCode, 0)
        XCTAssertEqual(crashDiagnostic.exceptionType, 1)

        let tree = crashDiagnostic.callStackTree

        XCTAssertTrue(tree.callStackPerThread)
        XCTAssertEqual(tree.callStacks.count, 1);

        let callStack = tree.callStacks[0]

        XCTAssertTrue(callStack.threadAttributed == true)
        XCTAssertEqual(callStack.rootFrames.count, 1)

        let frame = callStack.rootFrames[0]

        XCTAssertEqual(frame.binaryUUID, UUID(uuidString: "CDB53DDB-2337-4933-B62F-4356E6174AF0"))
        XCTAssertEqual(frame.offsetIntoBinaryTextSegment, 123)
        XCTAssertEqual(frame.sampleCount, 20)
        XCTAssertEqual(frame.binaryName, "testBinaryName")
        XCTAssertEqual(frame.address, 74565)
    }

    func testReadingSimulatedMacOSCrashDiagnosticsData() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "xcode_simulated_macOS_12", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        XCTAssertEqual(payload.crashDiagnostics?.count, 1)

        // on macOS, these dates are encoded in local time, which is a real pain
        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        XCTAssertEqual(payload.timeStampBegin, formatter.date(from: "2022-03-07 07:30:54"))
        XCTAssertEqual(payload.timeStampEnd, formatter.date(from: "2022-03-07 07:30:54"))
    }

    func testReadingSimulatedHangDiagnosticsData() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "xcode_simulated", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        XCTAssertEqual(payload.hangDiagnostics?.count, 1)
        let diagnostic = try XCTUnwrap(payload.hangDiagnostics?[0])

        XCTAssertEqual(diagnostic.metaData.applicationBuildVersion, "1")

        let tree = diagnostic.callStackTree

        XCTAssertTrue(tree.callStackPerThread)
        XCTAssertEqual(tree.callStacks.count, 1);

        let callStack = tree.callStacks[0]

        XCTAssertTrue(callStack.threadAttributed == true)
        XCTAssertEqual(callStack.rootFrames.count, 1)

        let frame = callStack.rootFrames[0]

        XCTAssertEqual(frame.offsetIntoBinaryTextSegment, 123)
        XCTAssertEqual(frame.address, 74565)
    }

    func testReadingSimulatedCPUExceptionDiagnosticsData() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "xcode_simulated", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        XCTAssertEqual(payload.cpuExceptionDiagnostics?.count, 1)
        let diagnostic = try XCTUnwrap(payload.cpuExceptionDiagnostics?[0])

        XCTAssertEqual(diagnostic.metaData.applicationBuildVersion, "1")

        let tree = diagnostic.callStackTree

        XCTAssertFalse(tree.callStackPerThread)
        XCTAssertEqual(tree.callStacks.count, 1);

        let callStack = tree.callStacks[0]

        XCTAssertNil(callStack.threadAttributed)
        XCTAssertEqual(callStack.rootFrames.count, 1)
    }

    func testRealPayloadWithSubframes() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "real_report", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])
        let payload = try DiagnosticPayload.from(data: data)

        XCTAssertEqual(payload.crashDiagnostics?.count, 2)

        let crashDiagnostic = try XCTUnwrap(payload.crashDiagnostics?[0])

        let tree = crashDiagnostic.callStackTree

        XCTAssertTrue(tree.callStackPerThread)
        XCTAssertEqual(tree.callStacks.count, 10);

        let callStack = tree.callStacks[0]

        XCTAssertTrue(callStack.threadAttributed == true)
        XCTAssertEqual(callStack.rootFrames.count, 1)
        XCTAssertEqual(callStack.rootFrames[0].subFrames?.count, 1)

        let frames = callStack.frames

        XCTAssertEqual(frames.count, 32)

        XCTAssertEqual(frames[0].binaryUUID, UUID(uuidString: "9156BE86-D4B6-3A81-8460-8728FA38C978"))
        XCTAssertEqual(frames[0].offsetIntoBinaryTextSegment, 6859616256)
        XCTAssertEqual(frames[0].sampleCount, 1)
        XCTAssertEqual(frames[0].binaryName, "libswiftCore.dylib")
        XCTAssertEqual(frames[0].address, 6859816880)

        XCTAssertEqual(frames[1].binaryUUID, UUID(uuidString: "9156BE86-D4B6-3A81-8460-8728FA38C978"))
        XCTAssertEqual(frames[1].offsetIntoBinaryTextSegment, 6859616256)
        XCTAssertEqual(frames[1].sampleCount, 1)
        XCTAssertEqual(frames[1].binaryName, "libswiftCore.dylib")
        XCTAssertEqual(frames[1].address, 6859816880)

        XCTAssertEqual(frames[30].binaryUUID, UUID(uuidString: "444F912B-06E7-395E-9E6E-D947B07401AC"))
        XCTAssertEqual(frames[30].offsetIntoBinaryTextSegment, 4303568896)
        XCTAssertEqual(frames[30].sampleCount, 1)
        XCTAssertEqual(frames[30].binaryName, "MetricKitTest")
        XCTAssertEqual(frames[30].address, 4303603064)

        XCTAssertEqual(frames[31].binaryUUID, UUID(uuidString: "77E57314-8A58-3064-90C0-8AF9A4745430"))
        XCTAssertEqual(frames[31].offsetIntoBinaryTextSegment, 6795280384)
        XCTAssertEqual(frames[31].sampleCount, 1)
        XCTAssertEqual(frames[31].binaryName, "libdyld.dylib")
        XCTAssertEqual(frames[31].address, 6795285912)
    }
}
