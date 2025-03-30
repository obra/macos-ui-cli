// swift-tools-version:5.7
// ABOUTME: This file defines the Swift package manifest for the MacOSUICLI tool.
// ABOUTME: It configures dependencies, targets, and build settings for the project.

import PackageDescription

let package = Package(
    name: "MacOSUICLI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "macos-ui-cli", targets: ["MacOSUICLI"]),
        .executable(name: "macos-ui-explorer", targets: ["MacOSUIExplorer"]),
        .executable(name: "AccessibilityExplorer", targets: ["AccessibilityExplorer"]),
        .library(name: "MacOSUICLILib", targets: ["MacOSUICLILib"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/andybest/linenoise-swift", from: "0.0.3")
    ],
    targets: [
        // Haxcessibility wrapper target
        .target(
            name: "Haxcessibility",
            dependencies: [],
            path: "vendor/Haxcessibility",
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
        
        .target(
            name: "MacOSUICLILib",
            dependencies: [
                "Haxcessibility"
            ],
            swiftSettings: [
                .define("HAXCESSIBILITY_AVAILABLE")
            ],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        
        .executableTarget(
            name: "MacOSUICLI",
            dependencies: [
                "MacOSUICLILib",
                "Haxcessibility",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "LineNoise", package: "linenoise-swift")
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
        ),
        
        .executableTarget(
            name: "MacOSUIExplorer",
            dependencies: [
                "MacOSUICLILib",
                "Haxcessibility",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            exclude: [
                "Info.plist"
            ],
            swiftSettings: [
                .define("HAXCESSIBILITY_AVAILABLE")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        
        .executableTarget(
            name: "AccessibilityExplorer",
            dependencies: [
                "Haxcessibility"
            ],
            path: "AccessibilityExplorer",
            exclude: [
                "README.md",
                "RUNNING.md",
                "UPDATES.md",
                "Package.swift",
                "SafeAccessibility.swift",
                "SafeExplorerApp.swift",
                "AccessibilityExplorerApp.swift"
            ],
            sources: ["BasicExplorerApp.swift"],
            swiftSettings: [
                .define("HAXCESSIBILITY_AVAILABLE")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
