// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NightCastCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "NightCastCore", targets: ["NightCastCore"])
    ],
    targets: [
        .target(name: "NightCastCore"),
        .testTarget(
            name: "NightCastCoreTests",
            dependencies: ["NightCastCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
