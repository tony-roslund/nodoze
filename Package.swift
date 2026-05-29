// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "nodoze",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Nodoze", targets: ["NodozeApp"]),
        .library(name: "NodozeCore", targets: ["NodozeCore"])
    ],
    targets: [
        .target(name: "NodozeCore"),
        .executableTarget(
            name: "NodozeApp",
            dependencies: ["NodozeCore"]
        ),
        .testTarget(
            name: "NodozeCoreTests",
            dependencies: ["NodozeCore"]
        )
    ]
)
