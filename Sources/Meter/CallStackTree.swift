//
//  CallStackTree.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-06-30.
//

import Foundation
#if os(iOS) || os(macOS)
import MetricKit
#endif

public struct Frame: Codable {
    public var binaryUUID: UUID?
    public var offsetIntoBinaryTextSegment: Int?
    public var sampleCount: Int?
    public var binaryName: String?
    public var address: Int
    public var subFrames: [Frame]?

    public init(binaryUUID: UUID? = nil, offsetIntoBinaryTextSegment: Int? = nil, sampleCount: Int? = nil, binaryName: String? = nil, address: Int, subFrames: [Frame]) {
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

    public var binaryLoadAddress: Int? {
        return offsetIntoBinaryTextSegment
    }

    public var approximateBinarySize: Int? {
        guard let loadAddress = binaryLoadAddress else {
            return nil
        }

        if loadAddress > address {
            return nil
        }

        return address - loadAddress + 1
    }
}

extension Frame: Hashable {
}

public class CallStack: NSObject, Codable {
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

public class CallStackTree: Codable {
    public let callStacks: [CallStack]
    public let callStackPerThread: Bool

    public static func from(data: Data) throws -> CallStackTree {
        return try JSONDecoder().decode(CallStackTree.self, from: data)
    }

    #if os(iOS) || os(macOS)
    @available(iOS 14.0, macOS 12.0, *)
    static func from(callStackTree: MXCallStackTree) throws -> CallStackTreeProtocol {
        let data = callStackTree.jsonRepresentation()

        return try from(data: data)
    }
    #endif

    public init(callStacks: [CallStack], callStackPerThread: Bool) {
        self.callStacks = callStacks
        self.callStackPerThread = callStackPerThread
    }
}

extension CallStackTree: CallStackTreeProtocol {
    public func jsonRepresentation() -> Data {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            return Data()
        }
    }
}