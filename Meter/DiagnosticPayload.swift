//
//  ConcreteDiagnostics.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-10-10.
//

import Foundation
#if os(iOS)
import MetricKit
#endif

public class DiagnosticPayload: DiagnosticPayloadProtocol, Codable {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        // "2020-10-10 19:35:24 +0000"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        return formatter
    }()

    enum CodingKeys: String, CodingKey {
        case timeStampBegin
        case timeStampEnd
        case internalCrashDiagnostics = "crashDiagnostics"
    }

    public let timeStampBegin: Date
    public let timeStampEnd: Date
    private let internalCrashDiagnostics: [CrashDiagnostic]?

    public static func from(data: Data) throws -> DiagnosticPayload {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .formatted(DiagnosticPayload.dateFormatter)

        return try decoder.decode(DiagnosticPayload.self, from: data)
    }

    #if os(iOS)
    @available(iOS 14.0, *)
    public static func from(payload: MXDiagnosticPayload) throws -> DiagnosticPayload {
        let data = payload.jsonRepresentation()

        return try from(data: data)
    }
    #endif

    public init(timeStampBegin: Date, timeStampEnd: Date, crashDiagnostics: [CrashDiagnostic]?) {
        self.timeStampBegin = timeStampBegin
        self.timeStampEnd = timeStampEnd
        self.internalCrashDiagnostics = crashDiagnostics
    }

    public var crashDiagnostics: [CrashDiagnosticProtocol]? {
        return internalCrashDiagnostics
    }

    public func jsonRepresentation() -> Data {
        let encoder = JSONEncoder()

        encoder.dateEncodingStrategy = .formatted(DiagnosticPayload.dateFormatter)

        return (try? encoder.encode(self)) ?? Data()
    }
}

public class CrashMetaData: MetaDataProtocol, Codable {
    public let deviceType: String
    public let applicationBuildVersion: String
    public let applicationVersion: String
    public let osVersion: String
    public let platformArchitecture: String
    public let regionFormat: String
    public let virtualMemoryRegionInfo: String?
    public let exceptionType: Int?
    public let terminationReason: String?
    public let exceptionCode: Int?
    public let signal: Int?

    enum CodingKeys: String, CodingKey {
        case applicationBuildVersion = "appBuildVersion"
        case applicationVersion = "appVersion"
        case osVersion
        case platformArchitecture
        case regionFormat
        case virtualMemoryRegionInfo
        case terminationReason
        case exceptionCode = "exceptionCode"
        case signal = "signal"
        case exceptionType = "exceptionType"
        case deviceType
    }

    public init(deviceType: String, applicationBuildVersion: String, applicationVersion: String, osVersion: String, platformArchitecture: String, regionFormat: String, virtualMemoryRegionInfo: String?, exceptionType: Int?, terminationReason: String?, exceptionCode: Int?, signal: Int?) {
        self.deviceType = deviceType
        self.applicationBuildVersion = applicationBuildVersion
        self.applicationVersion = applicationVersion
        self.osVersion = osVersion
        self.platformArchitecture = platformArchitecture
        self.regionFormat = regionFormat
        self.virtualMemoryRegionInfo = virtualMemoryRegionInfo
        self.exceptionType = exceptionType
        self.terminationReason = terminationReason
        self.exceptionCode = exceptionCode
        self.signal = signal
    }

    public func jsonRepresentation() -> Data {
        return (try? JSONEncoder().encode(self)) ?? Data()
    }
}

public class CrashDiagnostic: Codable {
    public let version: String
    private let internalMetaData: CrashMetaData
    private let internalCallStackTree: CallStackTree

    enum CodingKeys: String, CodingKey {
        case version
        case internalMetaData = "diagnosticMetaData"
        case internalCallStackTree = "callStackTree"
    }

    public init(metaData: CrashMetaData, callStackTree: CallStackTree) {
        self.version = "1.0.0"
        self.internalMetaData = metaData
        self.internalCallStackTree = callStackTree
    }

    public var applicationVersion: String {
        return internalMetaData.applicationVersion
    }

    public var virtualMemoryRegionInfo: String? {
        return internalMetaData.virtualMemoryRegionInfo
    }

    public func jsonRepresentation() -> Data {
        return (try? JSONEncoder().encode(self)) ?? Data()
    }
}

extension CrashDiagnostic: CrashDiagnosticProtocol {
    public var metaData: MetaDataProtocol {
        return internalMetaData
    }

    public var terminationReason: String? {
        return internalMetaData.terminationReason
    }

    public var signal: NSNumber? {
        return internalMetaData.signal.map({ NSNumber(value: $0) })
    }

    public var exceptionCode: NSNumber? {
        return internalMetaData.exceptionCode.map({ NSNumber(value: $0) })
    }

    public var callStackTree: CallStackTreeProtocol {
        return internalCallStackTree
    }

    public var exceptionType: NSNumber? {
        return internalMetaData.exceptionType.map({ NSNumber(value: $0) })
    }
}
