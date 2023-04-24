// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Meter",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12), .watchOS(.v3)],
    products: [
        .library(name: "Meter", targets: ["Meter"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "BinaryImage", publicHeadersPath: "."),
        .target(name: "Meter", dependencies: ["BinaryImage"]),
        .testTarget(name: "MeterTests",
                    dependencies: ["Meter"],
                    resources: [
                        .process("Resources"),
                    ]),
        .testTarget(name: "BinaryImageTests",
                    dependencies: ["BinaryImage"]),
    ]
)
