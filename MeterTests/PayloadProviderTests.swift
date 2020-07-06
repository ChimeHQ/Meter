//
//  PayloadProviderTests.swift
//  MeterTests
//
//  Created by Matt Massicotte on 2020-06-30.
//

import XCTest
@testable import Meter

class Subscriber: PayloadSubscriber {
    var onReceiveHandler: (([DiagnosticPayload]) -> Void)?

    func didReceive(_ payloads: [DiagnosticPayload]) {
        onReceiveHandler?(payloads)
    }
}

class PayloadProviderTests: XCTestCase {
    func testReceivingPayloads() {
        let provider = PayloadProvider.shared
        let subscriber = Subscriber()

        provider.add(subscriber)

        let expectation = XCTestExpectation(description: "payload delivery")
        var receivedPayloads: [DiagnosticPayload]?

        subscriber.onReceiveHandler = { (payloads) in
            receivedPayloads = payloads

            expectation.fulfill()
        }

        let simulatedCrash = CrashDiagnostic(callStackTree: CallStackTree(callStacks: [], callStackPerThread: true),
                                             applicationVersion: "1.0",
                                             terminationReason: "crash",
                                             virtualMemoryRegionInfo: "",
                                             exceptionType: "",
                                             exceptionCode: "",
                                             signal: "")

        let simulatedPayloads = [DiagnosticPayload(dateRange: Date()..<Date(), crashes: [simulatedCrash])]

        provider.deliver(simulatedPayloads)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedPayloads?.count, 1)
        XCTAssertEqual(receivedPayloads?[0].crashDiagnostics?.count, 1)

        let receivedCrash = receivedPayloads?[0].crashDiagnostics?[0]

        XCTAssertEqual(receivedCrash?.applicationVersion, "1.0")
    }

    func testRemovedSubscriber() {
        let provider = PayloadProvider.shared
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
