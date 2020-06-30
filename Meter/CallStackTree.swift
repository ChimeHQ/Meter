//
//  CallStackTree.swift
//  Meter
//
//  Created by Matt Massicotte on 2020-06-30.
//

import Foundation
import MetricKit

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
}
