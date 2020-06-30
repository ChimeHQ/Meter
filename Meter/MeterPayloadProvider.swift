//
//  MeterPayloadProvider.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-06-30.
//

import Foundation

@objc public protocol PayloadSubscriber {
    @objc optional func didReceive(_ payloads: [DiagnosticPayload])
}

public class Diagnostic: NSObject {
    public let callStackTree: CallStackTree
    public let applicationVersion: String

    public init(callStackTree: CallStackTree, applicationVersion: String) {
        self.callStackTree = callStackTree
        self.applicationVersion = applicationVersion
    }
}

public class CrashDiagnostic: Diagnostic {
    public let terminationReason: String
    public let virtualMemoryRegionInfo: String
    public let exceptionType: String
    public let exceptionCode: String
    public let signal: String

    public init(callStackTree: CallStackTree, applicationVersion: String, terminationReason: String, virtualMemoryRegionInfo: String = "", exceptionType: String = "", exceptionCode: String = "", signal: String = "") {
        self.terminationReason = terminationReason
        self.virtualMemoryRegionInfo = virtualMemoryRegionInfo
        self.exceptionType = exceptionType
        self.exceptionCode = exceptionCode
        self.signal = signal

        super.init(callStackTree: callStackTree, applicationVersion: applicationVersion)
    }
}

public class DiagnosticPayload: NSObject {
    public let timeStampBegin: Date
    public let timeStampEnd: Date

    public let crashDiagnostics: [CrashDiagnostic]?

    public init(timeStampBegin: Date, timeStampEnd: Date, crashes: [CrashDiagnostic]?) {
        self.timeStampBegin = timeStampBegin
        self.timeStampEnd = timeStampEnd
        self.crashDiagnostics = crashes

        super.init()
    }

    public convenience init(dateRange: Range<Date>, crashes: [CrashDiagnostic]) {
        self.init(timeStampBegin: dateRange.lowerBound, timeStampEnd: dateRange.upperBound, crashes: crashes)
    }

    public var dateRange: Range<Date> {
        return timeStampBegin..<timeStampEnd
    }
}

public class PayloadProvider {
    public static var shared: PayloadProvider = PayloadProvider()

    private var subscribers: [PayloadSubscriber]
    private let queue: OperationQueue

    public init() {
        self.subscribers = []
        self.queue = OperationQueue()

        queue.name = "com.chimehq.Meter.PayloadProvider"
        queue.maxConcurrentOperationCount = 1
    }

    public func addSubscriber(_ subscriber: PayloadSubscriber) {
        // make sure to avoid duplicates
        removeSubscriber(subscriber)

        queue.addOperation {
            self.subscribers.append(subscriber)
        }
    }

    public func removeSubscriber(_ subscriber: PayloadSubscriber) {
        queue.addOperation {
            guard let idx = self.subscribers.firstIndex(where: { $0 === subscriber }) else {
                // Match MetricKit semantics of silently ignoring this situation
                return
            }

            self.subscribers.remove(at: idx)
        }
    }
}

extension PayloadProvider {
    public func deliver(_ payloads: [DiagnosticPayload]) {
        queue.addOperation {
            for sub in self.subscribers {
                self.queue.addOperation {
                    sub.didReceive?(payloads)
                }
            }
        }
    }
}
