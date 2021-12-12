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

struct DynamicLibraryInfo {
    private let info: Dl_info
    private let address: Int

    init?(address: Int) {
        self.address = address

        let ptr = UnsafeRawPointer(bitPattern: address)
        var infoObj = Dl_info()

        guard dladdr(ptr, &infoObj) != 0 else {
            return nil
        }

        self.info = infoObj
    }

    init() {
        self.info = Dl_info(dli_fname: nil, dli_fbase: nil, dli_sname: nil, dli_saddr: nil)
        self.address = 0
    }

    var symbolName: String? {
        return info.dli_sname.map(String.init(cString:))
    }

    var symbolOffset: Int {
        return address - symbolAddress
    }

    var symbolAddress: Int {
        return info.dli_saddr.map({ Int(bitPattern: $0) }) ?? 0
    }

    var path: String? {
        return info.dli_fname.map(String.init(cString:))
    }

    var machOHeader: UnsafePointer<MachOHeader>? {
        return info.dli_fbase
            .map({ $0.bindMemory(to: MachOHeader.self, capacity: 1) })
            .map({ UnsafePointer($0) })
    }

    var loadAddress: Int {
        return info.dli_fbase.map({ Int(bitPattern: $0) }) ?? 0
    }

    func getUUID() -> UUID? {
        return machOHeader.map({ BinaryImageGetUUID($0) })
    }

    func makeBinary() -> Binary? {
        guard let uuid = getUUID() else {
            return nil
        }

        let size = address - loadAddress

        let name = path?.components(separatedBy: "/").last

        return Binary(uuid: uuid, loadAddress: loadAddress, approximateSize: size, name: name)
    }

    var symbolInfo: SymbolInfo {
        return SymbolInfo(symbol: symbolName ?? "", offset: symbolOffset)
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

        guard let info = DynamicLibraryInfo(address: processAddress) else {
            return []
        }

        return [info.symbolInfo]
    }
}
