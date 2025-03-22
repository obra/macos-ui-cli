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
        // Haxcessibility target, built directly from our source
        .target(
            name: "Haxcessibility",
            dependencies: [],
            exclude: [
                "Haxcessibility.xcodeproj",
                "TODO.mdown",
                "README.mdown",
                "LICENSE",
                "Resources"
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("Classes"),
                .headerSearchPath("Other Sources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        
        .executableTarget(
            name: "MacOSUICLI",
            dependencies: [
                "Haxcessibility",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            // Info.plist is handled separately for command-line tools
            swiftSettings: [
                .define("HAXCESSIBILITY_AVAILABLE")
            ],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        
        .testTarget(
            name: "MacOSUICLITests",
            dependencies: ["MacOSUICLI"],
            swiftSettings: [
                .define("HAXCESSIBILITY_AVAILABLE")
            ]
        )
    ]
)
