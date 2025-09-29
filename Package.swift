// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PoloManager",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PoloManager",
            targets: ["PoloManager"]
        ),
    ],
    dependencies: [
        // SwiftData for data persistence
        // No additional dependencies needed as we'll use native frameworks
    ],
    targets: [
        .target(
            name: "PoloManager",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "PoloManagerTests",
            dependencies: ["PoloManager"],
            path: "Tests"
        ),
    ]
)