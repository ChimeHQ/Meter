//
//  Diagnostic.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-10-10.
//

import Foundation
#if os(iOS)
import MetricKit
#endif

public protocol DiagnosticPayloadProtocol {
    func jsonRepresentation() -> Data

    var timeStampBegin: Date { get }
    var timeStampEnd: Date { get }

    var crashDiagnostics: [CrashDiagnosticProtocol]? { get }
}

public extension DiagnosticPayloadProtocol {
    func JSONRepresentation() -> Data {
        return jsonRepresentation()
    }

    var dateRange: Range<Date> {
        return timeStampBegin..<timeStampEnd
    }
}

public protocol DiagnosticProtocol {
    var applicationVersion: String { get }

    func jsonRepresentation() -> Data
}

public extension DiagnosticProtocol {
    func JSONRepresentation() -> Data {
        return jsonRepresentation()
    }
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
    func JSONRepresentation() -> Data

    var callStacks: [CallStack] { get }
    var callStackPerThread: Bool { get }
}
