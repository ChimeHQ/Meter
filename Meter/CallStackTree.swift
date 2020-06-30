//
//  CallStackTree.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-06-30.
//

import Foundation
#if os(iOS)
import MetricKit
#endif

public struct Frame: Codable {
    public var binaryUUID: UUID
    public var offsetIntoBinaryTextSegment: Int
    public var sampleCount: Int
    public var binaryName: String
    public var address: Int
}

public struct CallStack: Codable {
    public var threadAttributed: Bool
    public var rootFrames: [Frame]

    enum CodingKeys: String, CodingKey {
        case threadAttributed
        case rootFrames = "callStackRootFrames"
    }
}

public struct CallStackTree: Codable {
    public var callStacks: [CallStack]
    public var callStackPerThread: Bool

    static func from(data: Data) throws -> CallStackTree {
        return try JSONDecoder().decode(CallStackTree.self, from: data)
    }

    // I would like to add this API, but I'm unsure how to annotate it correctly so
    // it builds for all platforms with Xcode 11 and 12...
//#if os(iOS)
//    @available(iOS 14.0, *)
//    @available(macCatalyst, unavailable)
//    @available(tvOS, unavailable)
//    static func from(callStackTree: MXCallStackTree) throws -> CallStackTree {
//        let data = callStackTree.jsonRepresentation()
//
//        return try from(data: data)
//    }
//#endif
}
