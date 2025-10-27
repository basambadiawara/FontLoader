// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FontLoader",
    platforms: [
        .iOS(.v13), .macOS(.v11)
    ],
    products: [
        .library(name: "FontLoader", targets: ["FontLoader"])
    ],
    targets: [
        .target(
            name: "FontLoader",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
