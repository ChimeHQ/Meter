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

public struct Binary: Codable, Hashable {
    public var uuid: UUID
    public var loadAddress: Int
    public var approximateSize: Int
    public var name: String?

    public init(uuid: UUID, loadAddress: Int, approximateSize: Int, name: String?) {
        self.uuid = uuid
        self.loadAddress = loadAddress
        self.approximateSize = approximateSize
        self.name = name
    }

    public init?(uuid: String, loadAddress: Int, approximateSize: Int, name: String?) {
        guard let value = UUID(uuidString: uuid) else { return nil }

        self.uuid = value
        self.loadAddress = loadAddress
        self.approximateSize = approximateSize
        self.name = name
    }

    public var addressRange: Range<Int> {
        return loadAddress..<approximateSize
    }

    func contains(_ address: Int) -> Bool {
        return addressRange.contains(address)
    }
}

public struct Frame: Codable, Hashable {
    public var binaryUUID: UUID?
    public var offsetIntoBinaryTextSegment: Int?
    public var sampleCount: Int?
    public var binaryName: String?
    public var address: Int
    public var subFrames: [Frame]?
    public var symbolInfo: [SymbolInfo]?

    public init(binaryUUID: UUID? = nil, offsetIntoBinaryTextSegment: Int? = nil, sampleCount: Int? = nil, binaryName: String? = nil, address: Int, subFrames: [Frame]?, symbolInfo: [SymbolInfo]? = nil) {
        self.binaryUUID = binaryUUID
        self.offsetIntoBinaryTextSegment = offsetIntoBinaryTextSegment
        self.sampleCount = sampleCount
        self.binaryName = binaryName
        self.address = address
        self.subFrames = subFrames
        self.symbolInfo = symbolInfo
    }

    init(frame: Frame, symbolInfo: [SymbolInfo], subFrames: [Frame]?) {
        self.binaryUUID = frame.binaryUUID
        self.offsetIntoBinaryTextSegment = frame.offsetIntoBinaryTextSegment
        self.sampleCount = frame.sampleCount
        self.binaryName = frame.binaryName
        self.address = frame.address
        self.subFrames = subFrames
        self.symbolInfo = symbolInfo
    }

    public var flattenedFrames: [Frame] {
        return subFrames?.flatMap({ [$0] + $0.flattenedFrames }) ?? []
    }

    public func binary(withOffsetAsLoadAddress: Bool) -> Binary? {
        guard
            let uuid = binaryUUID,
            let offset = offsetIntoBinaryTextSegment
        else {
            return nil
        }

        let loadAddress = withOffsetAsLoadAddress ? offset : address - offset
        let size = address - loadAddress + 1

        return Binary(uuid: uuid,
                      loadAddress: loadAddress,
                      approximateSize: size,
                      name: binaryName)
    }

    public var isSimulated: Bool {
        return binaryName == "testBinaryName"
    }
}

public class CallStack: NSObject, Codable {
    /// Indicates which thread caused the crash
    public var threadAttributed: Bool?
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

    public var isSimulated: Bool {
        return rootFrames.first?.isSimulated == true
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
    public static func from(callStackTree: MXCallStackTree) throws -> CallStackTree {
        let data = callStackTree.jsonRepresentation()

        return try from(data: data)
    }
    #endif

    public init(callStacks: [CallStack], callStackPerThread: Bool) {
        self.callStacks = callStacks
        self.callStackPerThread = callStackPerThread
    }

    public func jsonRepresentation() -> Data {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            return Data()
        }
    }

    public var isSimulated: Bool {
        return callStacks.first?.isSimulated == true
    }
}
