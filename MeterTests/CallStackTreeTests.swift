//
//  CallStackTreeTests.swift
//  MeterTests
//
//  Created by Matt Massicotte on 2020-06-30.
//

import XCTest
@testable import Meter

class CallStackTreeTests: XCTestCase {

    func testParsingSimulatedData() throws {
        let string = """
{
"callStacks" : [
  {
    "threadAttributed" : true,
    "callStackRootFrames" : [
      {
        "binaryUUID" : "C7202336-F8EB-4D30-8346-D486FB29D4B1",
        "offsetIntoBinaryTextSegment" : 123,
        "sampleCount" : 20,
        "binaryName" : "testBinaryName",
        "address" : 74565
      }
    ]
  }
],
"callStackPerThread" : true
}
"""
        let data = try XCTUnwrap(string.data(using: .utf8))
        let tree = try XCTUnwrap(CallStackTree.from(data: data))

        XCTAssertTrue(tree.callStackPerThread)
        XCTAssertEqual(tree.callStacks.count, 1);

        let callStack = tree.callStacks[0]

        XCTAssertTrue(callStack.threadAttributed)
        XCTAssertEqual(callStack.rootFrames.count, 1)

        let frame = callStack.rootFrames[0]

        XCTAssertEqual(frame.binaryUUID, UUID(uuidString: "C7202336-F8EB-4D30-8346-D486FB29D4B1"))
        XCTAssertEqual(frame.offsetIntoBinaryTextSegment, 123)
        XCTAssertEqual(frame.sampleCount, 20)
        XCTAssertEqual(frame.binaryName, "testBinaryName")
        XCTAssertEqual(frame.address, 74565)
    }
}
