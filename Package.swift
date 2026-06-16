// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Gomoku",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "GomokuCore", targets: ["GomokuCore"])
    ],
    targets: [
        .target(name: "GomokuCore"),
        .testTarget(name: "GomokuCoreTests", dependencies: ["GomokuCore"])
    ]
)
