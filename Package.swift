// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Meter",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12)],
    products: [
        .library(name: "Meter", targets: ["Meter"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Meter", dependencies: [], path: "Meter/", exclude: ["Meter.xcconfig", "Info.plist"]),
        .testTarget(name: "MeterTests",
                    dependencies: ["Meter"],
                    path: "MeterTests/",
                    exclude: ["MeterTests.xcconfig", "Info.plist"],
                    resources: [
                        .copy("Resources"),
                    ]),
    ]
)
