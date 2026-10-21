// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YawnCastCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "YawnCastCore", targets: ["YawnCastCore"])
    ],
    targets: [
        .target(name: "YawnCastCore"),
        .testTarget(
            name: "YawnCastCoreTests",
            dependencies: ["YawnCastCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
