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
    var dateRange: Range<Date> {
        return timeStampBegin..<timeStampEnd
    }
}

public protocol MetaDataProtocol {
    var regionFormat: String { get }
    var osVersion: String { get }
    var deviceType: String { get }
    var applicationBuildVersion: String { get }

    @available(iOS 14.0, *)
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
