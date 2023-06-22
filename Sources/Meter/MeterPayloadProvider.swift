import Foundation
import os.log
#if canImport(MetricKit)
import MetricKit
#endif

public protocol MeterPayloadSubscriber: AnyObject {
    func didReceive(_ payloads: [DiagnosticPayload])
}

public class MeterPayloadManager: NSObject {
    public static var shared: MeterPayloadManager = MeterPayloadManager()

    private var subscribers: [MeterPayloadSubscriber]
    private let queue: OperationQueue
    private let logger: OSLog
    public var deliverMetricKitDiagnostics = true

	public static var metricKitDiagnosticsSupported: Bool {
#if canImport(MetricKit)
#if compiler(>=5.9)
		if #available(iOS 14.0, macOS 12.0, xrOS 1.0, *) {
			return true
		}
#else
		if #available(iOS 14.0, macOS 12.0, *) {
			return true
		}
#endif

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

#if canImport(MetricKit)
#if compiler(>=5.9)
		if #available(iOS 14.0, macOS 12.0, xrOS 1.0, *) {
			MXMetricManager.shared.add(self)
		}
#else
		if #available(iOS 14.0, macOS 12.0, *) {
			MXMetricManager.shared.add(self)
		}
#endif
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
    public func deliver(_ payloads: [DiagnosticPayload]) {
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

#if canImport(MetricKit)
@available(iOS 13.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension MeterPayloadManager: MXMetricManagerSubscriber {
#if compiler(>=5.9)
#if os(iOS) || os(xrOS)
	public func didReceive(_ payloads: [MXMetricPayload]) {
	}
#endif
#else
#if os(iOS)
	public func didReceive(_ payloads: [MXMetricPayload]) {
	}
#endif
#endif

#if compiler(>=5.9)
	@available(iOS 14.0, macOS 12.0, xrOS 1.0, *)
#else
	@available(iOS 14.0, macOS 12.0, *)
#endif
	@available(tvOS, unavailable)
	@available(watchOS, unavailable)
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        guard deliverMetricKitDiagnostics else { return }

        let internalPayloads = payloads
            .compactMap { payload -> DiagnosticPayload? in
                do {
                    return try DiagnosticPayload.from(payload: payload)
                } catch {
                    os_log("Failed to encode payload", log: self.logger, type: .error, String(describing: error))
                }

                return nil
            }

        deliver(internalPayloads)
    }
}
#endif
