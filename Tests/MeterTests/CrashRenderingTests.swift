import XCTest
@testable import Meter

final class CrashRenderingTests: XCTestCase {
    func testBinaries() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "real_report", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        let crashDiagnostic = try XCTUnwrap(payload.crashDiagnostics?[0])

        let binaries = crashDiagnostic.callStackTree.binaryImages
            .sorted(by: { $0.loadAddress < $1.loadAddress })

        XCTAssertEqual(binaries.count, 10)
        XCTAssertEqual(binaries[0], Binary(uuid: "444F912B-06E7-395E-9E6E-D947B07401AC",
                                           loadAddress: 4303568896,
                                           approximateSize: 41041,
                                           name: "MetricKitTest"))
        XCTAssertEqual(binaries[9], Binary(uuid: "9A318917-27DB-312E-91D6-81661034FCC6",
                                           loadAddress: 7966019584,
                                           approximateSize: 59521,
                                           name: "libsystem_pthread.dylib"))
    }

    func testSimulatedCrash() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "xcode_simulated", withExtension: "json"))
        let data = try Data(contentsOf: url, options: [])

        let payload = try XCTUnwrap(DiagnosticPayload.from(data: data))

        let crashDiagnostic = try XCTUnwrap(payload.crashDiagnostics?[0])

        let renderedCrash = crashDiagnostic.renderCrash()

        let expectedURL = try XCTUnwrap(Bundle.module.url(forResource: "xcode_simulated", withExtension: "crash"))
        let string = try String(contentsOf: expectedURL, encoding: .utf8)

        XCTAssertEqual(renderedCrash, string)
    }
}
