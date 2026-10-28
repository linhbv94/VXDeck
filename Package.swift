// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VXDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VXDeck",
            targets: ["VXDeck"]
        ),
        .library(
            name: "VXDeckCore",
            targets: ["VXDeckCore"]
        )
    ],
    targets: [
        .target(
            name: "VXDeckCore",
            path: "Sources/VXDeckCore"
        ),
        .executableTarget(
            name: "VXDeck",
            dependencies: ["VXDeckCore"],
            path: "Sources/VXDeck"
        ),
        .executableTarget(
            name: "VXDeckCoreTests",
            dependencies: ["VXDeckCore"],
            path: "Tests/VXDeckTests"
        )
    ]
)
