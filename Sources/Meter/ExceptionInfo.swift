import Foundation
import BinaryImage

public struct ExceptionInfo: Codable {
    public let name: String
    public let reason: String
    public let backtrace: [Frame]

    public init(name: String, reason: String, backtrace: [Frame]) {
        self.name = name
        self.reason = reason
        self.backtrace = backtrace
    }
}
