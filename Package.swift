// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Mac拍照软件",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Mac拍照软件",
            path: "Sources/Mac拍照软件",
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
