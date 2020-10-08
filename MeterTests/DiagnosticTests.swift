//
//  DiagnosticTests.swift
//  MeterTests
//
//  Created by Matt Massicotte on 2020-10-10.
//

import XCTest
@testable import Meter

class DiagnosticTests: XCTestCase {
    func testReadingSimulatedData() throws {
        let url = try XCTUnwrap(Bundle(for: CallStackTreeTests.self).url(forResource: "xcode_simulated", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        let crashDiagnostic = try XCTUnwrap(payload.crashDiagnostics?[0])

        XCTAssertEqual(crashDiagnostic.metaData.applicationBuildVersion, "1")
        XCTAssertEqual(crashDiagnostic.metaData.osVersion, "iPhone OS 14.0.1 (18A393)")
        XCTAssertEqual(crashDiagnostic.metaData.platformArchitecture, "arm64")
        XCTAssertEqual(crashDiagnostic.metaData.regionFormat, "CA")
        XCTAssertEqual(crashDiagnostic.virtualMemoryRegionInfo?.hasPrefix("0 is not in any region"), true)
        XCTAssertEqual(crashDiagnostic.applicationVersion, "1.0")
        XCTAssertEqual(crashDiagnostic.terminationReason, "Namespace SIGNAL, Code 0xb")
        XCTAssertEqual(crashDiagnostic.signal, NSNumber(value: 11))
        XCTAssertEqual(crashDiagnostic.exceptionCode, NSNumber(value: 0))
        XCTAssertEqual(crashDiagnostic.exceptionType, NSNumber(value: 1))

        let tree = crashDiagnostic.callStackTree

        XCTAssertTrue(tree.callStackPerThread)
        XCTAssertEqual(tree.callStacks.count, 1);

        let callStack = tree.callStacks[0]

        XCTAssertTrue(callStack.threadAttributed)
        XCTAssertEqual(callStack.rootFrames.count, 1)

        let frame = callStack.rootFrames[0]

        XCTAssertEqual(frame.binaryUUID, UUID(uuidString: "CDB53DDB-2337-4933-B62F-4356E6174AF0"))
        XCTAssertEqual(frame.offsetIntoBinaryTextSegment, 123)
        XCTAssertEqual(frame.sampleCount, 20)
        XCTAssertEqual(frame.binaryName, "testBinaryName")
        XCTAssertEqual(frame.address, 74565)
        XCTAssertEqual(frame.binaryRelativeAddress, 74565 - 123)
    }
}
