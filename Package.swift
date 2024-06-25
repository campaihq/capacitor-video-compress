// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorVideoCompress",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "CapacitorVideoCompress",
            targets: ["CapacitorVideoCompressPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", branch: "main")
    ],
    targets: [
        .target(
            name: "CapacitorVideoCompressPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/CapacitorVideoCompressPlugin"),
        .testTarget(
            name: "CapacitorVideoCompressPluginTests",
            dependencies: ["CapacitorVideoCompressPlugin"],
            path: "ios/Tests/CapacitorVideoCompressPluginTests")
    ]
)