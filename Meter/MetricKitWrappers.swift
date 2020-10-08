//
//  MetricKitWrappers.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-10-10.
//

import Foundation
#if os(iOS)
import MetricKit

@available(iOS 14.0, *)
public class MXDiagnosticPayloadWrapper: DiagnosticPayloadProtocol {
    private let payload: MXDiagnosticPayload

    init(payload: MXDiagnosticPayload) {
        self.payload = payload
    }

    public func jsonRepresentation() -> Data {
        return payload.jsonRepresentation()
    }

    public var timeStampBegin: Date {
        return payload.timeStampBegin
    }

    public var timeStampEnd: Date {
        return payload.timeStampEnd
    }

    public lazy var crashDiagnostics: [CrashDiagnosticProtocol]? = {
        return payload.crashDiagnostics?.map({ MXCrashDiagnosticDiagnosticWrapper(diagnostic: $0) })
    }()
}

@available(iOS 14.0, *)
public class MXCrashDiagnosticDiagnosticWrapper: CrashDiagnosticProtocol {
    private let diagnostic: MXCrashDiagnostic

    init(diagnostic: MXCrashDiagnostic) {
        self.diagnostic = diagnostic
    }

    public var applicationVersion: String {
        return diagnostic.applicationVersion
    }

    public var callStackTree: CallStackTreeProtocol {
        return MXCallStackTreeWrapper(tree: diagnostic.callStackTree)
    }
    
    public var terminationReason: String? {
        return diagnostic.terminationReason
    }

    public var virtualMemoryRegionInfo: String? {
        return diagnostic.virtualMemoryRegionInfo
    }

    public var exceptionType: NSNumber? {
        return diagnostic.exceptionType
    }

    public var exceptionCode: NSNumber? {
        return diagnostic.exceptionCode
    }

    public var signal: NSNumber? {
        return diagnostic.signal
    }

    public func jsonRepresentation() -> Data {
        return diagnostic.jsonRepresentation()
    }
}

@available(iOS 14.0, *)
public class MXCallStackTreeWrapper: CallStackTreeProtocol {
    private let tree: MXCallStackTree

    init(tree: MXCallStackTree) {
        self.tree = tree
    }

    public func JSONRepresentation() -> Data {
        return JSONData
    }

    private lazy var JSONData: Data = {
        return tree.jsonRepresentation()
    }()

    private lazy var internalCallStackTree: CallStackTreeProtocol? = {
        return try? CallStackTree.from(data: JSONData)
    }()

    public var callStacks: [CallStack] {
        return internalCallStackTree?.callStacks ?? []
    }

    public var callStackPerThread: Bool {
        return internalCallStackTree?.callStackPerThread ?? true
    }
}

#endif
