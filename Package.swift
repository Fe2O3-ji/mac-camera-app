// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Camera",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Camera",
            path: "Sources/Camera",
            resources: [
                .process("Assets.xcassets"),
                .process("Info.plist")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("Photos")
            ]
        ),
    ]
)
