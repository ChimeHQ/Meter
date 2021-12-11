//
//  PayloadProviderTests.swift
//  MeterTests
//
//  Created by Matt Massicotte on 2020-06-30.
//

import XCTest
@testable import Meter

class Subscriber: MeterPayloadSubscriber {
    var onReceiveHandler: (([DiagnosticPayload]) -> Void)?

    func didReceive(_ payloads: [DiagnosticPayload]) {
        onReceiveHandler?(payloads)
    }
}

class PayloadProviderTests: XCTestCase {
    func testReceivingPayloads() {
        let provider = MeterPayloadManager.shared
        let subscriber = Subscriber()

        provider.add(subscriber)

        let expectation = XCTestExpectation(description: "payload delivery")
        var receivedPayloads: [DiagnosticPayload]?

        subscriber.onReceiveHandler = { (payloads) in
            receivedPayloads = payloads

            expectation.fulfill()
        }

        let metaData = CrashMetaData(deviceType: "device",
                                     applicationBuildVersion: "1",
                                     applicationVersion: "1.0",
                                     osVersion: "abcdef",
                                     platformArchitecture: "arm64",
                                     regionFormat: "CA",
                                     virtualMemoryRegionInfo: nil,
                                     exceptionType: 5,
                                     terminationReason: "crash",
                                     exceptionCode: 5,
                                     signal: 5)
        let simulatedCrash = CrashDiagnostic(metaData: metaData,
                                             callStackTree: CallStackTree(callStacks: [], callStackPerThread: true))

        let simulatedPayloads = [DiagnosticPayload(timeStampBegin: Date(),
                                                   timeStampEnd: Date(),
                                                   crashDiagnostics: [simulatedCrash],
                                                   hangDiagnostics: nil,
                                                   cpuExceptionDiagnostics: nil,
                                                   diskWriteExceptionDiagnostics: nil)]

        provider.deliver(simulatedPayloads)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedPayloads?.count, 1)
        XCTAssertEqual(receivedPayloads?[0].crashDiagnostics?.count, 1)

        let receivedCrash = receivedPayloads?[0].crashDiagnostics?[0]

        XCTAssertEqual(receivedCrash?.applicationVersion, "1.0")
    }

    func testRemovedSubscriber() {
        let provider = MeterPayloadManager.shared
        let subscriber = Subscriber()

        provider.add(subscriber)
        let expectation = XCTestExpectation(description: "payload delivery")
        expectation.isInverted = true

        subscriber.onReceiveHandler = { (_) in
            expectation.fulfill()
        }

        provider.remove(subscriber)

        provider.deliver([])

        wait(for: [expectation], timeout: 1.0)
    }
}
