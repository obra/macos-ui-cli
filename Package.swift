// swift-tools-version:5.5
// ABOUTME: This file defines the Swift package manifest for the MacOSUICLI tool.
// ABOUTME: It configures dependencies, targets, and build settings for the project.

import PackageDescription

let package = Package(
    name: "MacOSUICLI",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "macos-ui-cli", targets: ["MacOSUICLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MacOSUICLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            cSettings: [
                .headerSearchPath("../../vendor/Haxcessibility/Classes"),
                .headerSearchPath("../../vendor/Haxcessibility/Other Sources")
            ]
        ),
        .testTarget(
            name: "MacOSUICLITests",
            dependencies: ["MacOSUICLI"]
        )
    ]
)
