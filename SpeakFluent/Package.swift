// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeakFluent",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SpeakFluentCore",
            targets: ["SpeakFluentCore"]
        )
    ],
    targets: [
        .target(
            name: "SpeakFluentCore",
            path: "SpeakFluent",
            exclude: [
                "Info.plist",
                "Assets.xcassets",
                "Preview Content",
                "SpeakFluentApp.swift"
            ]
        )
    ]
)
