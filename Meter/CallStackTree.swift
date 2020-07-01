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
    public var subFrames: [Frame]?

    public init(binaryUUID: UUID, offsetIntoBinaryTextSegment: Int, sampleCount: Int, binaryName: String, address: Int, subFrames: [Frame]) {
        self.binaryUUID = binaryUUID
        self.offsetIntoBinaryTextSegment = offsetIntoBinaryTextSegment
        self.sampleCount = sampleCount
        self.binaryName = binaryName
        self.address = address
        self.subFrames = subFrames
    }

    public var flattenedFrames: [Frame] {
        return subFrames?.flatMap({ [$0] + $0.flattenedFrames }) ?? []
    }
}

extension Frame: Hashable {
}

public struct CallStack: Codable {
    /// Indicates which thread caused the crash
    public var threadAttributed: Bool
    public var rootFrames: [Frame]

    enum CodingKeys: String, CodingKey {
        case threadAttributed
        case rootFrames = "callStackRootFrames"
    }

    public init(threadAttributed: Bool, rootFrames: [Frame]) {
        self.threadAttributed = threadAttributed
        self.rootFrames = rootFrames
    }

    /// Returns a single array of Frame objects
    public var frames: [Frame] {
        return rootFrames.flatMap({ [$0] + $0.flattenedFrames })
    }
}

extension CallStack: Hashable {
}

public struct CallStackTree: Codable {
    public var callStacks: [CallStack]
    public var callStackPerThread: Bool

    public static func from(data: Data) throws -> CallStackTree {
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

    public init(callStacks: [CallStack], callStackPerThread: Bool) {
        self.callStacks = callStacks
        self.callStackPerThread = callStackPerThread
    }

    // I'd really prefer to have this function match the MetricKit
    // signature, but JSON encoding can fail, and I'd prefer not
    // to make that failure silent.
    public func JSONRepresentation() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

extension CallStackTree: Hashable {
}

