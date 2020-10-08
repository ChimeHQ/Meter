//
//  CallStackTreeTests.swift
//  MeterTests
//
//  Created by Matt Massicotte on 2020-06-30.
//

import XCTest
@testable import Meter

class CallStackTreeTests: XCTestCase {
    func testRealPayloadWithSubframes() throws {
        let url = try XCTUnwrap(Bundle(for: CallStackTreeTests.self).url(forResource: "real_report", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let tree = try XCTUnwrap(CallStackTree.from(data: data))

        XCTAssertTrue(tree.callStackPerThread)
        XCTAssertEqual(tree.callStacks.count, 8);

        let callStack = tree.callStacks[0]

        XCTAssertTrue(callStack.threadAttributed)
        XCTAssertEqual(callStack.rootFrames.count, 1)
        XCTAssertEqual(callStack.rootFrames[0].subFrames?.count, 1)

        let frames = callStack.frames

        XCTAssertEqual(frames.count, 31)

        XCTAssertEqual(frames[0].binaryUUID, UUID(uuidString: "D6DFFB72-D6F2-377C-B99B-04599C3CE452"))
        XCTAssertEqual(frames[0].offsetIntoBinaryTextSegment, 7087943680)
        XCTAssertEqual(frames[0].sampleCount, 1)
        XCTAssertEqual(frames[0].binaryName, "libswiftCore.dylib")
        XCTAssertEqual(frames[0].address, 7088143428)

        XCTAssertEqual(frames[1].binaryUUID, UUID(uuidString: "D6DFFB72-D6F2-377C-B99B-04599C3CE452"))
        XCTAssertEqual(frames[1].offsetIntoBinaryTextSegment, 7087943680)
        XCTAssertEqual(frames[1].sampleCount, 1)
        XCTAssertEqual(frames[1].binaryName, "libswiftCore.dylib")
        XCTAssertEqual(frames[1].address, 7088143428)

        XCTAssertEqual(frames[29].binaryUUID, UUID(uuidString: "72730DE8-A4C7-32B1-9202-CADE74507762"))
        XCTAssertEqual(frames[29].offsetIntoBinaryTextSegment, 4329062400)
        XCTAssertEqual(frames[29].sampleCount, 1)
        XCTAssertEqual(frames[29].binaryName, "MetricKitTest")
        XCTAssertEqual(frames[29].address, 4329115408)

        XCTAssertEqual(frames[30].binaryUUID, UUID(uuidString: "B0000CCF-C56D-3662-8631-1B4831962316"))
        XCTAssertEqual(frames[30].offsetIntoBinaryTextSegment, 6834638848)
        XCTAssertEqual(frames[30].sampleCount, 1)
        XCTAssertEqual(frames[30].binaryName, "libdyld.dylib")
        XCTAssertEqual(frames[30].address, 6834645456)
    }
}
