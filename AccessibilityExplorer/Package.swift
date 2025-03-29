// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AccessibilityExplorer",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "accessibility-explorer", targets: ["AccessibilityExplorer"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AccessibilityExplorer",
            dependencies: [],
            path: "."
        )
    ]
)