// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalizeSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "LocalizeSDK", targets: ["LocalizeSDK"]),
    ],
    targets: [
        .target(
            name: "LocalizeSDK",
            path: "Sources/LocalizeSDK"
        ),
        .testTarget(
            name: "LocalizeSDKTests",
            dependencies: ["LocalizeSDK"]
        ),
    ]
)
