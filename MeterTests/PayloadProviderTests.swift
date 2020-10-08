//
//  PayloadProviderTests.swift
//  MeterTests
//
//  Created by Matt Massicotte on 2020-06-30.
//

import XCTest
@testable import Meter

class Subscriber: MeterPayloadSubscriber {
    var onReceiveHandler: (([DiagnosticPayloadProtocol]) -> Void)?

    func didReceive(_ payloads: [DiagnosticPayloadProtocol]) {
        onReceiveHandler?(payloads)
    }
}

class TestableDiagnosticPayload: DiagnosticPayloadProtocol {
    let timeStampBegin: Date
    let timeStampEnd: Date
    let crashDiagnostics: [CrashDiagnosticProtocol]?

    init(timeStampBegin: Date, timeStampEnd: Date, crashDiagnostics: [CrashDiagnosticProtocol]?) {
        self.timeStampBegin = timeStampBegin
        self.timeStampEnd = timeStampEnd
        self.crashDiagnostics = crashDiagnostics
    }

    func jsonRepresentation() -> Data {
        return Data()
    }
}

class TestableCrashDiagnostic: CrashDiagnosticProtocol {
    let callStackTree: CallStackTreeProtocol
    let terminationReason: String?
    let virtualMemoryRegionInfo: String?
    let exceptionType: NSNumber?
    let exceptionCode: NSNumber?
    let signal: NSNumber?
    let applicationVersion: String

    func jsonRepresentation() -> Data {
        return Data()
    }

    init(applicationVersion: String, callStackTree: CallStackTreeProtocol, terminationReason: String?, virtualMemoryRegionInfo: String?, exceptionType: NSNumber?, exceptionCode: NSNumber?, signal: NSNumber?) {
        self.callStackTree = callStackTree
        self.terminationReason = terminationReason
        self.virtualMemoryRegionInfo = virtualMemoryRegionInfo
        self.exceptionType = exceptionType
        self.exceptionCode = exceptionCode
        self.signal = signal
        self.applicationVersion = applicationVersion
    }
}

class PayloadProviderTests: XCTestCase {
    func testReceivingPayloads() {
        let provider = MeterPayloadManager.shared
        let subscriber = Subscriber()

        provider.add(subscriber)

        let expectation = XCTestExpectation(description: "payload delivery")
        var receivedPayloads: [DiagnosticPayloadProtocol]?

        subscriber.onReceiveHandler = { (payloads) in
            receivedPayloads = payloads

            expectation.fulfill()
        }

        let simulatedCrash = TestableCrashDiagnostic(applicationVersion: "1.0",
                                               callStackTree: CallStackTree(callStacks: [], callStackPerThread: true),
                                               terminationReason: "crash",
                                               virtualMemoryRegionInfo: "",
                                               exceptionType: 0,
                                               exceptionCode: 0,
                                               signal: 0)

        let simulatedPayloads = [TestableDiagnosticPayload(timeStampBegin: Date(), timeStampEnd: Date(), crashDiagnostics: [simulatedCrash])]

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
