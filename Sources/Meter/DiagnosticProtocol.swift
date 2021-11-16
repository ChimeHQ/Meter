//
//  Diagnostic.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-10-10.
//

import Foundation
#if os(iOS) || os(macOS)
import MetricKit
#endif

public protocol DiagnosticPayloadProtocol {
    func jsonRepresentation() -> Data

    var timeStampBegin: Date { get }
    var timeStampEnd: Date { get }

    var crashDiagnostics: [CrashDiagnosticProtocol]? { get }
}

public extension DiagnosticPayloadProtocol {
    var dateRange: Range<Date> {
        return timeStampBegin..<timeStampEnd
    }
}

public protocol MetaDataProtocol {
    var regionFormat: String { get }
    var osVersion: String { get }
    var deviceType: String { get }
    var applicationBuildVersion: String { get }

    var platformArchitecture: String { get }

    func jsonRepresentation() -> Data
}

public protocol DiagnosticProtocol {
    var applicationVersion: String { get }
    var metaData: MetaDataProtocol { get }

    func jsonRepresentation() -> Data
}

public protocol CrashDiagnosticProtocol: DiagnosticProtocol {
    var callStackTree: CallStackTreeProtocol { get }
    var terminationReason: String? { get }
    var virtualMemoryRegionInfo: String? { get }
    var exceptionType: NSNumber? { get }
    var exceptionCode: NSNumber? { get }
    var signal: NSNumber? { get }
}

public protocol CallStackTreeProtocol {
    func jsonRepresentation() -> Data

    var callStacks: [CallStack] { get }
    var callStackPerThread: Bool { get }
}

public extension CallStackTreeProtocol {
    var binaryImages: [Binary] {
        let frames = callStacks.flatMap({ $0.frames })

        var uniquedBinaries = [UUID: Binary]()

        // unique the binaries, and if we have multiple matches
        // keep the ones with the largest (ie more accurate) sizes
        for frame in frames {
            guard let binary = frame.binary else { continue }
            let uuid = binary.uuid

            guard let existing = uniquedBinaries[uuid] else {
                uniquedBinaries[uuid] = binary
                continue
            }

            if existing.approximateSize < binary.approximateSize {
                uniquedBinaries[uuid] = binary
            }
        }

        return Array(uniquedBinaries.values)
    }
}
