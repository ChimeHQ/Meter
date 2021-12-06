import Foundation
import BinaryImage

extension BinaryImage {
    static var imageMap: [UUID: BinaryImage] {
        var map: [UUID: BinaryImage] = [:]

        BinaryImageEnumerateLoadedImages { image, _ in
            BinaryImageEnumerateLoadCommands(image.header) { lcmd, code, stop in
                switch code {
                case UInt32(LC_UUID):
                    if let uuid = BinaryuImageUUIDFromLoadCommand(lcmd, code) {
                        map[uuid] = image
                    }

                    stop.pointee = true
                default:
                    break
                }
            }
        }

        return map
    }
}

public class DlfcnSymbolicator {
    private lazy var imageMap: [UUID: BinaryImage] = BinaryImage.imageMap

    public init() {
    }
}

extension DlfcnSymbolicator: Symbolicator {
    public func symbolicate(address: Int, in target: SymbolicationTarget) -> [SymbolInfo] {
        guard let loadedImage = imageMap[target.uuid] else {
            return []
        }

        let loadAddress = Int(bitPattern: loadedImage.header)
        let relativeAddress = address - target.loadAddress
        let processAddress = loadAddress + relativeAddress
        let ptr = UnsafeRawPointer(bitPattern: processAddress)
        var info: Dl_info = Dl_info()

        guard dladdr(ptr, &info) != 0 else {
            return []
        }

        let offset = processAddress - Int(bitPattern: info.dli_saddr)
        let name = String(cString: info.dli_sname)
        let symbolInfo = SymbolInfo(symbol: name, offset: offset)

        return [symbolInfo]
    }
}
