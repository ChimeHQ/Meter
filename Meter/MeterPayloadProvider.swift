//
//  MeterPayloadProvider.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-06-30.
//

import Foundation
import os.log
#if os(iOS)
import MetricKit
#endif

public protocol MeterPayloadSubscriber: AnyObject {
    func didReceive(_ payloads: [DiagnosticPayloadProtocol])
}

public class MeterPayloadManager: NSObject {
    public static var shared: MeterPayloadManager = MeterPayloadManager()

    private var subscribers: [MeterPayloadSubscriber]
    private let queue: OperationQueue
    private let logger: OSLog
    public var deliverMetricKitDiagnostics = true

    public static var metricKitDiagnosticsSupported: Bool {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            return true
        }
        #endif

        return false
    }

    public override init() {
        self.subscribers = []
        self.queue = OperationQueue()
        self.logger = OSLog(subsystem: "com.chimehq.Meter", category: "PayloadProvider")

        super.init()

        queue.name = "com.chimehq.Meter.PayloadProvider"
        queue.maxConcurrentOperationCount = 1

        #if os(iOS)
        if #available(iOS 14.0, *) {
            MXMetricManager.shared.add(self)
        }
        #endif
    }

    public func add(_ subscriber: MeterPayloadSubscriber) {
        // make sure to avoid duplicates
        remove(subscriber)

        queue.addOperation {
            self.subscribers.append(subscriber)
        }
    }

    public func remove(_ subscriber: MeterPayloadSubscriber) {
        queue.addOperation {
            guard let idx = self.subscribers.firstIndex(where: { $0 === subscriber }) else {
                // Match MetricKit semantics of silently ignoring this situation
                os_log("No matching subscriber to remove", log: self.logger, type: .fault)
                return
            }

            self.subscribers.remove(at: idx)
        }
    }
}

extension MeterPayloadManager {
    public func deliver(_ payloads: [DiagnosticPayloadProtocol]) {
        if payloads.isEmpty {
            os_log("Asked to deliver an empty payload array", log: self.logger, type: .fault)
            return
        }

        queue.addOperation {
            if self.subscribers.isEmpty {
                os_log("Asked to deliver payloads without any subscribers", log: self.logger, type: .fault)
                return
            }

            for sub in self.subscribers {
                self.queue.addOperation {
                    sub.didReceive(payloads)
                }
            }
        }
    }
}

#if os(iOS)
@available(iOS 13.0, *)
extension MeterPayloadManager: MXMetricManagerSubscriber {
    public func didReceive(_ payloads: [MXMetricPayload]) {
    }

    @available(iOS 14.0, *)
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        guard deliverMetricKitDiagnostics else { return }
        
        let payloads = payloads.map({ MXDiagnosticPayloadWrapper(payload: $0) })

        deliver(payloads)
    }
}
#endif
