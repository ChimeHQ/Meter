// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "Meter",
	platforms: [
		.macOS(.v10_13),
		.iOS(.v12),
		.tvOS(.v12),
		.watchOS(.v4),
		.visionOS(.v1),
	],
	products: [
		.library(name: "Meter", targets: ["Meter"]),
	],
	dependencies: [],
	targets: [
		.target(name: "BinaryImage", publicHeadersPath: "."),
		.target(name: "Meter", dependencies: ["BinaryImage"]),
		.testTarget(
			name: "MeterTests",
			dependencies: ["Meter"],
			resources: [
				.copy("Resources"),
			]
		),
		.testTarget(
			name: "BinaryImageTests",
			dependencies: ["BinaryImage"]
		),
	]
)

let swiftSettings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]

for target in package.targets {
	var settings = target.swiftSettings ?? []
	settings.append(contentsOf: swiftSettings)
	target.swiftSettings = settings
}
