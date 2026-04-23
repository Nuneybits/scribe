// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Scribe",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Scribe", targets: ["Scribe"])
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", exact: "0.18.0")
    ],
    targets: [
        .executableTarget(
            name: "Scribe",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit")
            ],
            path: "Sources/Scribe"
        ),
        .testTarget(
            name: "ScribeTests",
            dependencies: ["Scribe"],
            path: "Tests/ScribeTests"
        )
    ]
)
