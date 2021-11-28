import XCTest
@testable import BinaryImage

final class BinaryImageTests: XCTestCase {
    func testIteration() {
        var images: [BinaryImage] = []

        BinaryImageEnumerateLoadedImages { image, _ in
            images.append(image)
        }

        let matchingImage = images.first { image in
            let name = String(cString: image.name)

            return name == "/usr/lib/system/libsystem_kernel.dylib"
        }

        XCTAssertNotNil(matchingImage)
    }
}
