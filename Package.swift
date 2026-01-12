// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FontLoader",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "FontLoader",
            targets: ["FontLoader"]
        )
    ],
    targets: [
        .target(
            name: "FontLoader"
        )
    ]
)
